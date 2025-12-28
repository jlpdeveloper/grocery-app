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

const activeTab = ref('shopping-list')

const newItemName = ref('')
const isRecurring = ref(false)
const frequency = ref(1)
const quantity = ref(1)
const isSubmitting = ref(false)

const quantityOptions = Array.from({ length: 10 }, (_, i) => ({
  label: (i + 1).toString(),
  value: i + 1
}))

async function addItem() {
  if (!newItemName.value || !user.value) return

  isSubmitting.value = true
  try {
    let recurringItemId = null

    if (isRecurring.value) {
      const { data: recData, error: recError } = await supabase
        .from('recurring_items')
        .insert({
          name: newItemName.value,
          created_by: user.value.sub,
          frequency: frequency.value,
          frequency_type: 'weeks'
        })
        .select()
        .single()

      if (recError) throw recError
      recurringItemId = recData.id
    }

    const { error: listError } = await supabase
      .from('list_items')
      .insert({
        name: newItemName.value,
        user_id: user.value.sub,
        recurring_item_id: recurringItemId,
        quantity: quantity.value
      })

    if (listError) throw listError

    // Reset form
    newItemName.value = ''
    isRecurring.value = false
    frequency.value = 1
    quantity.value = 1

    // Refresh data
    await refreshNuxtData(['shopping-list', 'recurring-items'])
  } catch (error) {
    console.error('Error adding item:', error)
  } finally {
    isSubmitting.value = false
  }
}

// Fetch shopping list items with user profiles
const { data: listItems } = await useAsyncData('shopping-list', async () => {
  const { data, error } = await supabase
    .from('list_items')
    .select(`
      *,
      user_profile!user_id (
        name
      )
    `)
  if (error) throw error
  return data
}, {
  watch: [user]
})

const groupedShoppingList = computed(() => {
  if (!listItems.value) return {}

  const groups: Record<string, typeof listItems.value> = {}

  // Sort by user name first as requested
  const sortedItems = [...listItems.value].sort((a, b) => {
    const nameA = a.user_profile?.name || ''
    const nameB = b.user_profile?.name || ''
    return nameA.localeCompare(nameB)
  })

  sortedItems.forEach((item) => {
    const userName = item.user_profile?.name || 'Unknown'
    if (!groups[userName]) {
      groups[userName] = []
    }
    groups[userName].push(item)
  })
  return groups
})

// Fetch all recurring items (all users have read access for suggestions)
const { data: allRecurringItems } = await useAsyncData('recurring-items', async () => {
  if (!user.value) return []
  const { data, error } = await supabase
    .from('recurring_items')
    .select('*')
  if (error) throw error
  return data
}, {
  watch: [user]
})

const myRecurringItems = computed(() => {
  if (!allRecurringItems.value || !user.value) return []
  return allRecurringItems.value.filter(item => item.created_by === user.value.sub)
})

const suggestedItems = computed(() => {
  if (!allRecurringItems.value) return []

  const now = new Date()
  return allRecurringItems.value.filter((item) => {
    // Already in the shopping list?
    const isInList = listItems.value?.some(li => li.recurring_item_id === item.id)
    if (isInList) return false

    if (!item.last_bought) return true

    const lastBought = new Date(item.last_bought)
    const frequencyWeeks = item.frequency || 1
    const nextDue = new Date(lastBought)
    nextDue.setDate(nextDue.getDate() + (frequencyWeeks * 7))

    return now >= nextDue
  })
})

async function addSuggestedItem(item: { id: number, name: string }) {
  if (!user.value) return

  try {
    const { error } = await supabase
      .from('list_items')
      .insert({
        name: item.name,
        user_id: user.value.sub,
        recurring_item_id: item.id,
        quantity: 1
      })

    if (error) throw error

    await refreshNuxtData('shopping-list')
  } catch (error) {
    console.error('Error adding suggested item:', error)
  }
}
function formatDate(dateString: string) {
  // Supabase returns YYYY-MM-DD for date columns.
  // Appending T00:00:00 ensures it's treated as a local date by new Date()
  // instead of being parsed as UTC and shifting back a day in some timezones.
  return new Date(`${dateString}T00:00:00`).toLocaleDateString()
}
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

    <UTabs v-model="activeTab" :items="tabs" class="w-full">
      <template #content="{ item }">
        <!-- Shopping List Tab -->
        <div v-if="item.value === 'shopping-list'" class="space-y-6 pt-4">
          <!-- Suggested Items -->
          <div v-if="suggestedItems.length > 0" class="space-y-2">
            <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wider px-2">
              Suggestions
            </h2>
            <div class="flex flex-wrap gap-2 px-2">
              <UButton
                v-for="suggested in suggestedItems"
                :key="suggested.id"
                size="xs"
                variant="soft"
                icon="i-lucide-plus"
                @click="addSuggestedItem(suggested)"
              >
                {{ suggested.name }}
                <span v-if="suggested.last_bought" class="text-[10px] opacity-60 ml-1">
                  ({{ formatDate(suggested.last_bought) }})
                </span>
                <span v-else class="text-[10px] opacity-60 ml-1">
                  (Never)
                </span>
              </UButton>
            </div>
          </div>

          <!-- Add Item Form -->
          <UCard>
            <form class="space-y-4" @submit.prevent="addItem">
              <div class="flex flex-col sm:flex-row gap-4 items-end">
                <UFormField label="Item Name" class="flex-1 w-full">
                  <UInput v-model="newItemName" placeholder="e.g. Milk" class="w-full" />
                </UFormField>

                <UFormField label="Qty" class="w-20">
                  <USelect
                    v-model="quantity"
                    :items="quantityOptions"
                    class="w-full"
                  />
                </UFormField>

                <div class="flex items-center gap-4 h-10">
                  <UCheckbox v-model="isRecurring" label="Recurring?" />
                </div>

                <UFormField v-if="isRecurring" label="Every (weeks)" class="w-24">
                  <UInput v-model="frequency" type="number" min="1" />
                </UFormField>

                <UButton
                  type="submit"
                  icon="i-lucide-plus"
                  :loading="isSubmitting"
                  :disabled="!newItemName"
                >
                  Add
                </UButton>
              </div>
            </form>
          </UCard>

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
              <li v-for="recItem in myRecurringItems" :key="recItem.id" class="p-4">
                <div class="flex items-center justify-between mb-1">
                  <span class="font-medium">{{ recItem.name }}</span>
                  <UButton
                    icon="i-lucide-shopping-cart"
                    size="sm"
                    variant="soft"
                    label="Add to List"
                    @click="addSuggestedItem(recItem)"
                  />
                </div>
                <div class="text-xs text-gray-500 flex gap-4">
                  <span>Every {{ recItem.frequency }} {{ recItem.frequency_type }}</span>
                  <span>Last: {{ recItem.last_bought ? formatDate(recItem.last_bought) : 'Never' }}</span>
                </div>
              </li>
            </ul>
          </UCard>
        </div>
      </template>
    </UTabs>
  </div>
</template>
