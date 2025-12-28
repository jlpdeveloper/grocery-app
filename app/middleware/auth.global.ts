export default defineNuxtRouteMiddleware(async (to) => {
  const user = useSupabaseUser()
  const client = useSupabaseClient()

  // On server-side, if we don't have a user, we might want to wait or skip
  // to avoid premature redirects since the client might have the session in LocalStorage
  if (import.meta.server) {
    if (user.value) {
      if (to.path === '/login') {
        return navigateTo('/')
      }
      return
    }
    // If no user on server, don't redirect yet, let the client handle it
    // This prevents the "refresh redirects to login" issue when cookies are not yet synced
    return
  }

  // Wait for user to be initialized if we're coming from a magic link
  // or if we're on the client and might need to hydrate the session
  if (!user.value) {
    const isMagicLink = to.hash.includes('access_token') ||
                       to.query.code ||
                       to.query.token_hash ||
                       to.path === '/confirm' // common callback path

    // If it's a magic link or we're just loading the app, wait a bit for Supabase to initialize
    const maxWait = isMagicLink ? 2000 : 500 // Wait longer for magic links
    const start = Date.now()

    while (!user.value && (Date.now() - start) < maxWait) {
      await new Promise(resolve => setTimeout(resolve, 50))
    }
  }

  if (!user.value && to.path !== '/login') {
    return navigateTo('/login')
  }

  if (user.value && to.path === '/login') {
    return navigateTo('/')
  }
})
