<script setup lang="ts">
const user = useSupabaseUser()
const supabase = useSupabaseClient()
const router = useRouter()

async function handleSignOut() {
  await supabase.auth.signOut()
  router.push('/login')
}
</script>

<template>
  <div class="p-4">
    <UPageHero
      v-if="user"
      :title="`Welcome, ${user.email}`"
      description="You are successfully logged into the Family Grocery app."
    >
      <template #links>
        <UButton
          color="neutral"
          variant="subtle"
          icon="i-lucide-log-out"
          @click="handleSignOut"
        >
          Sign Out
        </UButton>
      </template>
    </UPageHero>
  </div>
</template>
