# 🎬 CinéRoom - Exclusive Cinema Experience Platform 🍿

## Description

A Rails 8.0.2 platform for booking private screenings of independent films in unique venues. Users can discover exclusive events, meet film crews, and experience cinema in intimate settings like galleries, rooftops, and private mansions.

**Live Demo**: https://cineroom-95309b4cb0ca.herokuapp.com/

## Tech Stack

- **Backend**: Ruby on Rails 8.0.2
- **Frontend**: Stimulus + Tailwind CSS
- **Database**: PostgreSQL
- **Authentication**: Devise
- **Payments**: Stripe API
- **Emails**: ActionMailer
- **Maps**: Geocoder + Leaflet
- **Admin**: ActiveAdmin
- **Deployment**: Heroku

## Features

### For Users

- Discover and book exclusive film screenings
- Secure payment processing via Stripe
- Email confirmations and reminders
- Post-event reviews and ratings
- Personal booking dashboard

### For Admins

- Complete CRUD for movies and events
- Real-time booking management
- Participant communications
- Revenue analytics
- Interactive venue maps

### Technical

- 100% responsive design (mobile-first)
- RESTful API architecture
- MVC pattern with service objects
- Comprehensive validations

## 📦 Installation

### Prerequisites

- Ruby 3.0+
- Rails 8.0.2
- PostgreSQL
- Node.js (for Stimulus)

### Setup Instructions

```bash
# Clone the repository
git clone https://github.com/your-username/cineroom.git
cd cineroom

# Install dependencies
bundle install
npm install

# Database setup
rails db:create
rails db:migrate
rails db:seed

# Environment variables (create .env file)
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
STRIPE_SECRET_KEY=your_stripe_secret_key
SMTP_USERNAME=your_smtp_username
SMTP_PASSWORD=your_smtp_password

# Launch the application
rails server
```

## 🎮 How to Use

1. **Discover** exclusive events on the homepage
2. **Browse** available screenings with filters
3. **View details** - film synopsis, venue, crew present
4. **Create account** (email + password only)
5. **Book securely** via Stripe payment
6. **Receive confirmation** email with practical details
7. **Attend** the magical screening experience
8. **Leave review** and discover new events

### 📱 Responsive Design

- **Mobile-first** approach with Tailwind breakpoints
- **Touch-friendly** navigation and interactions
- **Progressive enhancement** from mobile to desktop
- **Cross-device consistency** and performance

###

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## 🙏 Acknowledgments

- **The Hacking Project** for the comprehensive Ruby on Rails training
- **Stripe** for the seamless payment integration
- **Tailwind CSS** for the beautiful responsive design
- **Independent filmmakers** who inspire unique cinema experiences

## 📞 Support

For support, email contact@cineroom.com or create an issue in this repository.

---

## 🤝 Team Collaboration

### Git Workflow

- Théo BANNERY
- Florian BENOIT
- Mathieu MARILLER

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

---

**🎬 Built with ❤️ and Rails 8.0.2 for the ultimate cinema experience!**

_"Where independent cinema meets exclusive experiences"_ ✨🍿

**Live Demo**: https://cineroom-95309b4cb0ca.herokuapp.com/
