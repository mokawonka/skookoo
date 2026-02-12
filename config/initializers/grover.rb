Grover.configure do |config|
  config.options = {
    format: 'png',
    viewport: { width: 1200, height: 630 },
    executable_path: '/usr/bin/chromium-browser', 
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  }
end