# Family Grocery App

A mobile-friendly family grocery application built with Nuxt 4, Nuxt UI, and Supabase. This app allows family members to maintain individual recurring grocery lists and a shared shopping list.

## 🚀 Features

- **Collaborative Shopping List**: View items from all users, grouped by display name.
- **Recurring Items**: Personal management of frequent purchases with customizable frequency.
- **Easy Addition**: Quickly copy recurring items to the main shopping list.
- **Smart Completion**: Marking items as "bought" updates the `last_bought` date on linked recurring items.
- **Mobile-First Design**: Optimized for handheld use with a responsive interface.
- **Secure Authentication**: Support for Email/Password and Magic Link via Supabase.

## 🛠 Tech Stack

- **Framework**: [Nuxt 4](https://nuxt.com/)
- **UI Components**: [Nuxt UI](https://ui.nuxt.com/)
- **Backend/Auth/Database**: [Supabase](https://supabase.com/)
- **Icons**: [Lucide](https://lucide.dev/) (via Nuxt UI)

## 🔐 Security Warning (Critical)

This project uses environment variables for sensitive configurations. **Never commit your `.env` or `.env.local` files to a public repository.**

1. Ensure `.env` and `.env.local` are in your `.gitignore`.
2. Use the provided `.env.example` as a template for your local setup.
3. Keep your Supabase Service Role keys secret and only use them in server-side code if necessary.

## 🏁 Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (includes npm) installed.
- A [Supabase](https://supabase.com/) project.

### Setup

1. Clone the repository.
2. Install dependencies:
   ```bash
   npm install
   ```
3. Copy `.env.example` to `.env` and fill in your Supabase credentials:
   ```bash
   cp .env.example .env
   ```

### Development

Start the development server:
```bash
npm run dev
```

### Production

Build for production:
```bash
npm run build
```

Preview the production build locally:
```bash
npm run preview
```

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
