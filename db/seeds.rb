require "securerandom"
require "bcrypt"

# =====================================================
# CONFIGURATION
# =====================================================

USER_COUNT      = ENV.fetch("USERS", 1000).to_i
MAX_DISTINCT_NAMES = ENV.fetch("NAMES", 200).to_i
BATCH_SIZE      = ENV.fetch("BATCH_SIZE", 500).to_i  

puts "Seeding #{USER_COUNT} users..."
puts "Using #{MAX_DISTINCT_NAMES} distinct names..."
puts "Batch size: #{BATCH_SIZE}"

# =====================================================
# DATA POOLS
# =====================================================

FIRST_NAMES = %w[
  John Jane Alex Emma Lucas Mia Noah Olivia Liam Ava
  Ethan Sophia Daniel Isabella Michael Charlotte
  Benjamin Amelia Henry Harper Sebastian Evelyn
  Theodore Abigail Samuel Emily Jack Ella
  Leo Chloe Gabriel Nora
]

LAST_NAMES = %w[
  Smith Johnson Brown Williams Jones Garcia Miller Davis
  Wilson Anderson Thomas Moore Martin Jackson Thompson
  White Harris Clark Lewis Robinson Walker Young Allen
  King Wright Scott Torres Nguyen Hill Flores Green
]

FONTS       = %w[serif sans-serif dyslexic]

LOCATIONS   = %w[
  Paris London Berlin Madrid Rome Lisbon Vienna
  Montreal Chicago Boston Toronto Sydney Auckland
  Tokyo Seoul Singapore Dubai Barcelona Amsterdam
]

BIOS = [
  "Book lover",
  "Reader and writer",
  "Coffee and literature",
  "Exploring new ideas",
  "Always learning",
  "Digital reader",
  "Notes and highlights enthusiast",
  "Curious mind"
]

# =====================================================
# NAME POOL
# =====================================================

ALL_NAMES = FIRST_NAMES.product(LAST_NAMES).map { |f, l| "#{f} #{l}" }
actual_name_count = [MAX_DISTINCT_NAMES, ALL_NAMES.size].min
NAME_POOL = ALL_NAMES.sample(actual_name_count).freeze

# =====================================================
# PRE-HASH PASSWORD ONCE
#
# BCrypt::Engine::MIN_COST (4) is ~250x faster than the default (12).
# This is safe for seed/test data — never use MIN_COST in production.
# We hash once and reuse the digest string for every row.
# =====================================================

puts "Pre-hashing password (cost=#{BCrypt::Engine::MIN_COST})..."
HASHED_PASSWORD = BCrypt::Password.create("password123", cost: BCrypt::Engine::MIN_COST)
puts "Password hashed. Starting inserts..."

# =====================================================
# SEED USERS
# =====================================================

# Determine the correct column name Devise uses for the password digest.
# Common values: :encrypted_password (Devise) or :password_digest (has_secure_password).
PASSWORD_COLUMN = User.column_names.include?("encrypted_password") \
  ? :encrypted_password \
  : :password_digest

timestamp = Time.current
batch     = []
total_inserted = 0

USER_COUNT.times do |i|
  batch << {
    email:                    "user#{i}_#{SecureRandom.hex(3)}@example.com",
    username:                 "user#{i}_#{SecureRandom.hex(3)}",
    name:                     NAME_POOL.sample,
    PASSWORD_COLUMN =>        HASHED_PASSWORD.to_s,
    mana:                     rand(0..1000),
    votes:                    {},        
    darkmode:                 [true, false].sample,
    font:                     FONTS.sample,
    allownotifications:       [true, false].sample,
    hooked:                   nil,
    bio:                      BIOS.sample,
    location:                 LOCATIONS.sample,
    following:                [],
    followers:                [],
    emailnotifications:       [true, false].sample,
    private_profile:          false,
    pending_follow_requests:  [],
    created_at:               timestamp,
    updated_at:               timestamp,
  }

  if batch.size >= BATCH_SIZE
    User.insert_all!(batch)        
    total_inserted += batch.size
    batch.clear
    percent = (total_inserted.to_f / USER_COUNT * 100).round(1)
    puts "Progress: #{percent}% (#{total_inserted}/#{USER_COUNT})"
  end
end

# Flush the last partial batch
unless batch.empty?
  User.insert_all!(batch)
  total_inserted += batch.size
  puts "Progress: 100.0% (#{total_inserted}/#{USER_COUNT})"
end

puts "Done. Inserted #{total_inserted} users."