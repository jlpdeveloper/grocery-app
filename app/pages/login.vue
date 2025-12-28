<script setup lang="ts">
definePageMeta({
  layout: 'default'
})

const supabase = useSupabaseClient()
const toast = useToast()
const router = useRouter()

const loading = ref(false)
const email = ref('')
const password = ref('')

const tabs = [
  { label: 'Password', icon: 'i-lucide-lock', value: 'password' },
  { label: 'Magic Link', icon: 'i-lucide-wand-2', value: 'magic-link' }
]

async function handlePasswordLogin() {
  if (loading.value) return
  loading.value = true

  try {
    const { error } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value
    })

    if (error) throw error

    toast.add({
      title: 'Success',
      description: 'You have been logged in.',
      color: 'success'
    })

    router.push('/')
  } catch (error) {
    const message = error instanceof Error ? error.message : 'An unknown error occurred'
    toast.add({
      title: 'Login failed',
      description: message,
      color: 'error'
    })
  } finally {
    loading.value = false
  }
}

async function handleMagicLinkLogin() {
  if (loading.value) return
  loading.value = true

  try {
    const { error } = await supabase.auth.signInWithOtp({
      email: email.value,
      options: {
        emailRedirectTo: window.location.origin
      }
    })

    if (error) throw error

    toast.add({
      title: 'Email sent',
      description: 'Check your inbox for the magic link.',
      color: 'success'
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'An unknown error occurred'
    toast.add({
      title: 'Error',
      description: message,
      color: 'error'
    })
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="flex flex-col items-center justify-center min-h-[calc(100vh-100px)] px-4">
    <UCard class="w-full max-w-sm">
      <template #header>
        <div class="text-center">
          <h1 class="text-2xl font-bold">
            Family Grocery
          </h1>
          <p class="text-sm text-gray-500 mt-1">
            Sign in to your account
          </p>
        </div>
      </template>

      <UTabs :items="tabs" class="w-full">
        <template #content="{ item }">
          <div v-if="item.value === 'password'" class="space-y-4 pt-4">
            <form @submit.prevent="handlePasswordLogin" class="space-y-4">
              <UFormField label="Email" name="email">
                <UInput
                  v-model="email"
                  type="email"
                  placeholder="email@example.com"
                  icon="i-lucide-mail"
                  class="w-full"
                  required
                />
              </UFormField>

              <UFormField label="Password" name="password">
                <UInput
                  v-model="password"
                  type="password"
                  placeholder="••••••••"
                  icon="i-lucide-lock"
                  class="w-full"
                  required
                />
              </UFormField>

              <UButton
                type="submit"
                block
                :loading="loading"
              >
                Sign In
              </UButton>
            </form>
          </div>

          <div v-else-if="item.value === 'magic-link'" class="space-y-4 pt-4">
            <form @submit.prevent="handleMagicLinkLogin" class="space-y-4">
              <UFormField label="Email" name="email">
                <UInput
                  v-model="email"
                  type="email"
                  placeholder="email@example.com"
                  icon="i-lucide-mail"
                  class="w-full"
                  required
                />
              </UFormField>

              <p class="text-xs text-gray-500">
                We'll email you a magic link for a password-free sign in.
              </p>

              <UButton
                type="submit"
                block
                :loading="loading"
                variant="subtle"
              >
                Send Magic Link
              </UButton>
            </form>
          </div>
        </template>
      </UTabs>
    </UCard>
  </div>
</template>
