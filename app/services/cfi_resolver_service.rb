# frozen_string_literal: true

require "epub/parser"
require "epub/cfi"
require "epub/searcher"

# Monkey-patch to fix bug in epub-parser gem v0.5.0
# The gem passes options as a positional hash instead of keyword arguments
module EPUB
  module Searcher
    class << self
      def search_text(epub, word, **options)
        Publication.search_text(epub.package, word, **options)
      end
    end
  end
end

# Resolves a text quote to an EPUB CFI by searching inside the EPUB using epub-parser's Searcher.
# Returns the first matching CFI so agents can create highlights with the correct location.
class CfiResolverService

  class Result
    attr_reader :cfi, :quote_found

    def initialize(cfi:, quote_found:)
      @cfi = cfi
      @quote_found = quote_found
    end

    def success?
      cfi.present?
    end
  end

  # @param epub_blob [ActiveStorage::Blob] the EPUB file (e.g. document.epub.epub_file.blob)
  # @param quote [String] exact text to find in the EPUB (will try normalized if exact fails)
  # @return [CfiResolverService::Result]
  def self.call(epub_blob, quote)
    new(epub_blob, quote).call
  end

  def initialize(epub_blob, quote)
    @epub_blob = epub_blob
    @quote = quote.to_s.strip
  end

  def call
    return Result.new(cfi: nil, quote_found: nil) if @quote.blank?

    begin
      @epub_blob.open do |temp_file|
        book = EPUB::Parser.parse(temp_file.path)
        cfi_str, quote_found = find_first_cfi(book, @quote)
        Result.new(cfi: cfi_str, quote_found: quote_found)
      end
    rescue => e
      Rails.logger.error "[CfiResolver] Error resolving CFI: #{e.class}: #{e.message}"
      Result.new(cfi: nil, quote_found: nil)
    end
  end

  private

  def find_first_cfi(book, quote)
    return [nil, nil] if quote.blank?
  
    Rails.logger.info "[CfiResolver] === START SEARCH for '#{quote[0..80]}...' (#{quote.length} chars) ==="
  
    # 1. Exact
    results = EPUB::Searcher.search_text(book, quote)
    Rails.logger.info "[CfiResolver] Exact search → #{results.size} results"
  
    if results.any?
      step = results.first.parent_steps.to_a[1]&.index
      Rails.logger.info "[CfiResolver] Exact match at itemref step: #{step}"
      return [enriched_cfi_string(book, results.first), quote]
    end
  
    # 2. Normalized whitespace
    normalized = quote.gsub(/\s+/, " ").strip
    results = EPUB::Searcher.search_text(book, normalized)
    Rails.logger.info "[CfiResolver] Whitespace-normalized search → #{results.size} results"
  
    if results.any?
      step = results.first.parent_steps.to_a[1]&.index
      Rails.logger.info "[CfiResolver] Whitespace match at itemref step: #{step}"
      return [enriched_cfi_string(book, results.first), normalized]
    end
  
    # 3. Aggressive (remove punctuation + lowercase) — often helps a lot
    aggressive = normalized.downcase.gsub(/[^\w\s]/, " ").gsub(/\s+/, " ").strip
    results = EPUB::Searcher.search_text(book, aggressive)
    Rails.logger.info "[CfiResolver] Aggressive search → #{results.size} results"
  
    if results.any?
      step = results.first.parent_steps.to_a[1]&.index
      Rails.logger.info "[CfiResolver] Aggressive match at itemref step: #{step}"
      return [enriched_cfi_string(book, results.first), aggressive]
    end
  
    Rails.logger.warn "[CfiResolver] No matches found after all attempts"
    [nil, nil]
  end

  def enriched_cfi_string(book, result)
    raw_cfi = result.to_cfi.to_s
    Rails.logger.info "[CfiResolver] Raw CFI before enrichment: #{raw_cfi}"
  
    parent_steps = result.parent_steps.to_a
    return raw_cfi if parent_steps.size < 2
  
    itemref_step = parent_steps[1]
    return raw_cfi unless itemref_step.type == :itemref
  
    array_idx = (itemref_step.index / 2) - 1
    return raw_cfi if array_idx < 0
  
    itemref = book.package.spine.itemrefs[array_idx]
    return raw_cfi if itemref.nil?
  
    manifest_item = book.package.manifest.items.find { |m| m.id == itemref.idref }
    href = manifest_item&.href&.to_s&.strip
    href = itemref.item&.href&.to_s&.strip if href.blank?
  
    return raw_cfi if href.blank?
  
    # Better: target the itemref step right after /6/
    if raw_cfi =~ %r{epubcfi\(/6/(\d+)}
      itemref_num = $1
      enriched = raw_cfi.sub(%r{/6/#{itemref_num}}, "/6/#{itemref_num}[#{href}]")
      Rails.logger.info "[CfiResolver] SUCCESS → Enriched CFI: #{enriched}"
      return enriched
    end
  
    Rails.logger.info "[CfiResolver] Could not enrich, returning raw: #{raw_cfi}"
    raw_cfi
  end
end
