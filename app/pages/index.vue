<script setup lang="ts">
const user = useSupabaseUser()
const supabase = useSupabaseClient()
const router = useRouter()

async function handleSignOut() {
  await supabase.auth.signOut()
  router.push('/login')
}

const tabs = [
  { label: 'Shopping List', icon: 'i-lucide-shopping-basket', value: 'shopping-list' },
  { label: 'Recurring Items', icon: 'i-lucide-refresh-cw', value: 'recurring' }
]

const shoppingList = [
  { id: 1, name: 'Milk', user: 'John', quantity: 2 },
  { id: 2, name: 'Bread', user: 'Jane', quantity: 1 },
  { id: 3, name: 'Eggs', user: 'John', quantity: 12 },
  { id: 4, name: 'Apples', user: 'Jane', quantity: 6 }
]

const groupedShoppingList = computed(() => {
  const groups: Record<string, typeof shoppingList> = {}
  shoppingList.forEach((item) => {
    if (!groups[item.user]) {
      groups[item.user] = []
    }
    groups[item.user].push(item)
  })
  return groups
})

const recurringItems = [
  { id: 1, name: 'Coffee', frequency: 7, frequencyType: 'days', lastBought: '2025-12-20' },
  { id: 2, name: 'Paper Towels', frequency: 30, frequencyType: 'days', lastBought: '2025-11-25' }
]
</script>

<template>
  <div class="max-w-2xl mx-auto p-4 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-bold">
          Welcome back!
        </h1>
        <p class="text-sm text-gray-500">
          {{ user?.email }}
        </p>
      </div>
      <UButton
        color="neutral"
        variant="subtle"
        icon="i-lucide-log-out"
        size="sm"
        @click="handleSignOut"
      >
        Sign Out
      </UButton>
    </div>

    <UTabs :items="tabs" class="w-full">
      <template #content="{ item }">
        <!-- Shopping List Tab -->
        <div v-if="item.value === 'shopping-list'" class="space-y-6 pt-4">
          <div v-for="(items, userName) in groupedShoppingList" :key="userName" class="space-y-2">
            <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wider px-2">
              {{ userName }}'s List
            </h2>
            <UCard :ui="{ body: 'p-0' }">
              <ul class="divide-y divide-gray-200 dark:divide-gray-800">
                <li v-for="listItem in items" :key="listItem.id" class="p-3 flex items-center justify-between">
                  <div class="flex items-center gap-3">
                    <UCheckbox />
                    <span>{{ listItem.name }}</span>
                    <span class="text-xs text-gray-400">x{{ listItem.quantity }}</span>
                  </div>
                  <UButton
                    color="error"
                    variant="ghost"
                    icon="i-lucide-trash-2"
                    size="xs"
                  />
                </li>
              </ul>
            </UCard>
          </div>

          <div class="flex justify-end pt-2">
            <UButton icon="i-lucide-check-check">
              Mark all as bought
            </UButton>
          </div>
        </div>

        <!-- Recurring Items Tab -->
        <div v-else-if="item.value === 'recurring'" class="space-y-4 pt-4">
          <div class="flex justify-between items-center px-2">
            <h2 class="text-lg font-semibold">
              My Recurring Items
            </h2>
            <UButton icon="i-lucide-plus" size="sm">
              Add Item
            </UButton>
          </div>

          <UCard :ui="{ body: 'p-0' }">
            <ul class="divide-y divide-gray-200 dark:divide-gray-800">
              <li v-for="recItem in recurringItems" :key="recItem.id" class="p-4">
                <div class="flex items-center justify-between mb-1">
                  <span class="font-medium">{{ recItem.name }}</span>
                  <UButton
                    icon="i-lucide-shopping-cart"
                    size="sm"
                    variant="soft"
                    label="Add to List"
                  />
                </div>
                <div class="text-xs text-gray-500 flex gap-4">
                  <span>Every {{ recItem.frequency }} {{ recItem.frequencyType }}</span>
                  <span>Last: {{ recItem.lastBought }}</span>
                </div>
              </li>
            </ul>
          </UCard>
        </div>
      </template>
    </UTabs>
  </div>
</template>
