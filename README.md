# <img src="app/assets/images/skookoo_logo_600.png" alt="Skookoo Logo" width="300">

A social network for people who love reading books and discovering content on the internet. Manage highlights, share insights, and connect with fellow readers.

## 🌟 Key Features

- **Universal Highlighting**: Chrome extension for highlighting any text on the web
- **Social Reading**: Share and discover highlights from books and articles
- **Rich Discussions**: Comment on highlights and engage with the community
- **Personal Library**: Organize your reading highlights and notes
- **Cross-Platform**: Web app and browser extension for seamless experience

## 🍎 Quick Start

### Prerequisites

This application requires Ruby 3.2.6 and Rails 7.2. Follow these instructions to set up your development environment on Ubuntu.

### Installation

#### 1. Install System Dependencies

```bash
# Install dependencies with apt
sudo apt update
sudo apt install build-essential rustc libssl-dev libyaml-dev zlib1g-dev libgmp-dev git
```

#### 2. Install Mise Version Manager

```bash
# Install Mise version manager
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate)"' >> ~/.bashrc
source ~/.bashrc
```

#### 3. Install Ruby and Rails

```bash
# Install Ruby globally with Mise
mise use -g ruby@3.2.6

# Install Rails 7.2
gem install rails -v "~> 7.2"
```

#### 4. Setup the Application

```bash
# Clone the repository
git clone <repository-url>
cd skookoo

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate

# Start the development server
rails server
```

Visit `http://localhost:3000` to see the application running.

## � Chrome Extension

**Skookoo includes a Chrome extension** that allows you to highlight any text on the web and save it to your account. 

### Extension Features:
- **Universal Highlighting**: Highlight text on any website
- **One-Click Save**: Instantly save highlights to your Skookoo account
- **Auto-Sync**: Highlights sync across all your devices
- **Quick Access**: View and manage highlights without leaving the current page
- **Social Sharing**: Share highlights directly from the extension

### Installation:
1. Visit the Chrome Web Store (link coming soon)
2. Click "Add to Chrome"
3. Sign in with your Skookoo account
4. Start highlighting any text on the web!

## 🍇 Features

- **Highlight Management**: Create, edit, and organize reading highlights
- **Rich Text Support**: ActionText integration for comments and replies
- **API Endpoints**: RESTful API for external integrations
- **User Authentication**: Secure session-based authentication
- **File Attachments**: ActiveStorage for document management

## 🍓 Testing

Run the test suite with:

```bash
# Run all tests
rails test

# Run specific test files
rails test test/controllers/application_controller_test.rb

# Run tests with verbose output
rails test -v
```

## 🍊 Test Suite Status

The application includes a comprehensive test suite covering:
- Authentication and authorization
- API endpoints and status codes
- Model validations and callbacks
- Controller actions and responses
- Integration scenarios

## 🍋 Development

### Environment Variables

Copy the example environment file:

```bash
cp .env.example .env
```

Configure the following variables as needed:
- `RAILS_ENV`: Environment (development/test/production)
- `SECRET_KEY_BASE`: Rails secret key base
- Database configuration


## 🍉 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 🍍 License

This project is licensed under the MIT License.

---

**Built with ❤️ using Rails 7.2**