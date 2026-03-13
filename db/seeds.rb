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
# USERNAME POOLS
# =====================================================

USERNAME_ADJECTIVES = %w[
  silent golden dark swift lucky wild bright sharp
  lazy cool calm brave bold fuzzy tiny clever
  cosmic frosted neon blazing hollow rusty velvet
  stormy gentle fierce ancient lunar solar
]

USERNAME_NOUNS = %w[
  fox wolf bear eagle hawk owl raven panda
  pixel blade echo drift spark flare ghost
  ridge storm creek vale peak dusk dawn
  cipher nomad sage monk scribe wanderer
  comet orbit nebula quasar pulsar
]

USERNAME_SUFFIXES = %w[
  reads books pages ink shelf lit prose
  tales words story lore verse chapter
]

# Patterns that mimic how real users pick usernames
def generate_username(used)
  100.times do
    candidate = case rand(6)
    when 0
      # adjective + noun: "silentfox", "goldenowl"
      "#{USERNAME_ADJECTIVES.sample}#{USERNAME_NOUNS.sample}"
    when 1
      # adjective + noun + number: "darkwolf42"
      "#{USERNAME_ADJECTIVES.sample}#{USERNAME_NOUNS.sample}#{rand(10..999)}"
    when 2
      # firstname + number: "emma94"
      "#{FIRST_NAMES.sample.downcase}#{rand(10..9999)}"
    when 3
      # noun + suffix: "foxreads", "wolftales"
      "#{USERNAME_NOUNS.sample}#{USERNAME_SUFFIXES.sample}"
    when 4
      # firstname + noun: "lucaswolf", "miaecho"
      "#{FIRST_NAMES.sample.downcase}#{USERNAME_NOUNS.sample}"
    when 5
      # adjective + suffix + number: "goldenreads7"
      "#{USERNAME_ADJECTIVES.sample}#{USERNAME_SUFFIXES.sample}#{rand(1..99)}"
    end

    return candidate unless used.include?(candidate)
  end

  # Fallback: guaranteed unique
  "reader_#{SecureRandom.hex(4)}"
end

# =====================================================
# NAME POOL
# =====================================================

ALL_NAMES = FIRST_NAMES.product(LAST_NAMES).map { |f, l| "#{f} #{l}" }
actual_name_count = [MAX_DISTINCT_NAMES, ALL_NAMES.size].min
NAME_POOL = ALL_NAMES.sample(actual_name_count).freeze

# =====================================================
# PRE-HASH PASSWORD ONCE
# =====================================================

puts "Pre-hashing password (cost=#{BCrypt::Engine::MIN_COST})..."
HASHED_PASSWORD = BCrypt::Password.create("password123", cost: BCrypt::Engine::MIN_COST)
puts "Password hashed. Starting inserts..."

# =====================================================
# SEED USERS
# =====================================================

PASSWORD_COLUMN = User.column_names.include?("encrypted_password") \
  ? :encrypted_password \
  : :password_digest

timestamp      = Time.current
batch          = []
total_inserted = 0
used_usernames = Set.new

USER_COUNT.times do |i|
  username = generate_username(used_usernames)
  used_usernames << username

  batch << {
    email:                    "user#{i}_#{SecureRandom.hex(3)}@example.com",
    username:                 username,
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

unless batch.empty?
  User.insert_all!(batch)
  total_inserted += batch.size
  puts "Progress: 100.0% (#{total_inserted}/#{USER_COUNT})"
end

puts "Done. Inserted #{total_inserted} users."