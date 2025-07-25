# 🎬 CinéRoom - Exclusive Cinema Experience Platform

> **Full-Stack Development Project** completed as part of The Hacking Project (THP) Full-Stack Developer Bootcamp validation.

## 📖 Project Overview

CinéRoom is a modern Ruby on Rails 8.0 platform that connects cinema enthusiasts with exclusive private film screenings in unique venues. The platform enables users to discover independent films, book intimate screening experiences, and connect with filmmakers in unconventional locations like art galleries, rooftops, and private mansions.

**🌐 Live Demo**: [cineroom-95309b4cb0ca.herokuapp.com](https://cineroom-95309b4cb0ca.herokuapp.com/)

---

## 🎯 Key Features

### 🎥 For Movie Enthusiasts

- **Discover** curated independent films and exclusive screenings
- **Book** secure payments via Stripe integration
- **Experience** intimate cinema in unique venues
- **Review** and rate films after screenings
- **Dashboard** to manage bookings and preferences

### 🎬 For Film Creators

- **Submit** movies for approval with poster uploads
- **Organize** private screening events
- **Manage** capacity, pricing, and venue details
- **Track** audience engagement and reviews

### 👨‍💼 For Administrators

- **Comprehensive** movie and event management via ActiveAdmin
- **Real-time** booking and participant oversight
- **Analytics** for revenue and attendance tracking
- **GDPR-compliant** user data management with cookie consent

---

## 🛠️ Technology Stack

| Category           | Technologies                           |
| ------------------ | -------------------------------------- |
| **Backend**        | Ruby 3.4.2, Rails 8.0.2                |
| **Frontend**       | Stimulus JS, Tailwind CSS 4.1          |
| **Database**       | PostgreSQL with ActiveRecord           |
| **Authentication** | Devise with Confirmable                |
| **Payments**       | Stripe API integration                 |
| **File Storage**   | Cloudinary (production), ActiveStorage |
| **Job Processing** | SolidQueue (Rails 8.0 native)          |
| **Email**          | ActionMailer with Letter Opener (dev)  |
| **Admin Panel**    | ActiveAdmin with custom styling        |
| **Maps**           | Leaflet with Geocoder                  |
| **Deployment**     | Heroku with PostgreSQL addon           |
| **Cache**          | SolidCache (Rails 8.0 native)          |

---

## ✨ Modern Rails 8.0 Features

- **SolidQueue**: Native background job processing without Redis
- **SolidCache**: Built-in caching solution
- **Kamal**: Modern deployment configuration
- **Authentication**: Secure user management with email confirmation
- **GDPR Compliance**: Cookie consent system with French localization
- **Responsive Design**: Mobile-first Tailwind CSS implementation

---

## 🚀 Installation & Setup

### Prerequisites

- Ruby 3.4.2+
- Rails 8.0.2
- PostgreSQL 14+
- Node.js 18+ (for Stimulus)

### Local Development Setup

```bash
# Clone the repository
git clone https://github.com/Paarroo/cine_room.git
cd cine_room

# Install Ruby dependencies
bundle install

# Install JavaScript dependencies
npm install

# Database setup
rails db:create
rails db:migrate
rails db:seed

# Start the development server
rails server
```

### Environment Variables

Create a `.env` file in the root directory:

```env
# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...

# Email Configuration (optional for development)
SMTP_USERNAME=your_smtp_username
SMTP_PASSWORD=your_smtp_password

# Cloudinary Configuration (for file uploads)
CLOUDINARY_URL=cloudinary://...
```

---

## 📱 User Experience

### Registration & Authentication

1. **GDPR-compliant** registration with cookie consent
2. **Email confirmation** required for account activation
3. **Secure authentication** with Devise

### Booking Flow

1. **Browse** curated film events with filtering
2. **View** detailed movie information and venue details
3. **Select** seats and proceed to secure Stripe checkout
4. **Receive** confirmation email with event details
5. **Attend** exclusive screening experience

### Post-Event

1. **Rate** and review the film experience
2. **Discover** new events based on preferences
3. **Track** booking history in personal dashboard

---

## 🔒 Security & Compliance

- **GDPR Compliance**: Full cookie consent system with French localization
- **Data Protection**: Secure user data handling and privacy controls
- **Payment Security**: PCI-compliant Stripe integration
- **Authentication**: Devise with email confirmation and secure sessions
- **Admin Security**: Role-based access control with ActiveAdmin

---

## 🎨 Design & UX

- **Mobile-First**: Responsive design optimized for all devices
- **Modern Styling**: Tailwind CSS 4.1 with custom design system
- **Interactive Elements**: Stimulus controllers for dynamic UX
- **Accessibility**: Semantic HTML and keyboard navigation support
- **Performance**: Optimized asset pipeline and caching strategies

---

## 📊 Project Architecture

```
app/
├── controllers/          # MVC Controllers with RESTful routing
├── models/              # ActiveRecord models with validations
├── views/               # ERB templates with partials
├── javascript/          # Stimulus controllers and importmaps
├── assets/              # Stylesheets and images
├── admin/               # ActiveAdmin configuration
└── mailers/             # Email templates and delivery
```

---

## 🎓 Learning Outcomes (THP Bootcamp)

This project demonstrates mastery of:

- **Full-Stack Development**: Complete Ruby on Rails application
- **Database Design**: Complex associations and data modeling
- **API Integration**: Stripe payments and external services
- **Authentication**: Secure user management with Devise
- **Admin Interfaces**: ActiveAdmin customization
- **Modern Rails**: Rails 8.0 features and best practices
- **Frontend Development**: Stimulus JS and responsive design
- **Deployment**: Production deployment on Heroku
- **Testing**: Comprehensive test coverage with RSpec
- **Code Quality**: Clean code principles and MVC architecture

---

## 🚀 Deployment

### Heroku Production Deployment

The application is deployed on Heroku with:

- **PostgreSQL** database addon
- **Cloudinary** for file storage
- **Custom domain** configuration
- **SSL/TLS** encryption
- **Environment-based** configuration

### Key Production Features

- **Database seeding** with sample data
- **Email delivery** via SMTP
- **Asset precompilation** with Tailwind CSS
- **Background jobs** with SolidQueue
- **Error monitoring** with Sentry integration

---

## 🤝 Contributing

This project was developed as part of The Hacking Project bootcamp curriculum. While primarily an educational project, contributions and feedback are welcome for learning purposes.

- Théo BANNERY
- Florian BENOIT
- Mathieu MARILLER

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

---

## 🙏 Acknowledgments

- **The Hacking Project (THP)** - For providing comprehensive full-stack development training
- **Rails Community** - For the amazing framework and ecosystem
- **Stripe** - For secure payment processing infrastructure
- **Heroku** - For reliable cloud hosting platform
- **Independent Filmmakers** - For inspiring unique cinema experiences

---

**🎬 Built with ❤️ and Rails 8.0.2 as part of THP Full-Stack Developer Bootcamp**

_"Where independent cinema meets modern web development"_ ✨🍿
