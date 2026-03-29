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
const selectedCategory = ref('Other')
const isRecurring = ref(false)
const frequency = ref(1)
const quantity = ref(1)
const isSubmitting = ref(false)
const checkedItems = ref<Set<number>>(new Set())

// List Management State
const selectedListIdCookie = useCookie<number | null>('selected-list-id', {
  maxAge: 60 * 60 * 24 * 365, // 1 year
  path: '/'
})
const selectedListId = ref<number | null>(selectedListIdCookie.value)

// Watch for selection changes to update cookie
watch(selectedListId, (newId) => {
  selectedListIdCookie.value = newId
})

const isCreatingList = ref(false)
const newListName = ref('')
const isDeletingList = ref(false)

// Inline Edit State
const editingId = ref<number | null>(null)
const editName = ref('')
const isUpdating = ref(false)

// Delete State
const deletingId = ref<number | null>(null)
const isDeleting = ref(false)

const toast = useToast()

const categoryOptions = [
  { label: 'Pharmacy', value: 'Pharmacy' },
  { label: 'Grocery', value: 'Grocery' },
  { label: 'Pet', value: 'Pet' },
  { label: 'Craft', value: 'Craft' },
  { label: 'Electronics', value: 'Electronics' },
  { label: 'Clothing', value: 'Clothing' },
  { label: 'Hardware', value: 'Hardware' },
  { label: 'No Category', value: 'Other' }
]

const quantityOptions = Array.from({ length: 10 }, (_, i) => ({
  label: (i + 1).toString(),
  value: i + 1
}))

// Fetch all list items (to calculate total count across all lists)
const { data: allListItems } = await useAsyncData('all-list-items', async () => {
  const { data, error } = await supabase
    .from('list_items')
    .select('id, list_id')
  if (error) throw error
  return data
}, {
  watch: [user]
})

const itemsNotShownSummary = computed(() => {
  if (!allListItems.value || !shoppingLists.value) return null

  const otherItems = allListItems.value.filter(item => item.list_id !== selectedListId.value)
  if (otherItems.length === 0) return null

  const otherListIds = new Set(otherItems.map(item => item.list_id))
  const listCount = otherListIds.size

  return `${otherItems.length} item${otherItems.length > 1 ? 's' : ''} in ${listCount} list${listCount > 1 ? 's' : ''} not shown`
})

async function addItem() {
  if (!newItemName.value || !selectedListId.value) return

  isSubmitting.value = true
  try {
    let recurringItemId = null

    if (isRecurring.value) {
      const { data: recData, error: recError } = await supabase
        .from('recurring_items')
        .insert({
          name: newItemName.value,
          created_by: user.value?.sub || null,
          frequency: frequency.value,
          frequency_type: 'weeks',
          category: selectedCategory.value
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
        user_id: user.value?.sub || null,
        recurring_item_id: recurringItemId,
        quantity: quantity.value,
        list_id: selectedListId.value,
        category: selectedCategory.value
      })

    if (listError) throw listError

    toast.add({
      title: 'Success',
      description: `Added ${newItemName.value} to list`,
      color: 'success'
    })

    // Reset form
    newItemName.value = ''
    selectedCategory.value = 'Other'
    isRecurring.value = false
    frequency.value = 1
    quantity.value = 1

    // Refresh data
    await refreshNuxtData(['shopping-list', 'recurring-items', 'all-list-items'])
  } catch (error) {
    const err = error as { message?: string }
    toast.add({
      title: 'Error',
      description: err.message || 'Failed to add item',
      color: 'error'
    })
    console.error('Error adding item:', error)
  } finally {
    isSubmitting.value = false
  }
}

// Fetch shopping lists
const { data: shoppingLists, refresh: refreshLists } = await useAsyncData('shopping-lists', async () => {
  const { data, error } = await supabase
    .from('shopping_lists')
    .select('*')
    .order('created_at', { ascending: true })
  if (error) throw error

  if (data && data.length > 0) {
    if (selectedListId.value) {
      // Check if current selection still exists
      const exists = data.some(l => l.id === selectedListId.value)
      if (!exists) {
        const defaultList = data.find(l => l.is_default) || data[0]
        selectedListId.value = defaultList.id
      }
    } else {
      // No selection, check cookie (already handled by ref initialization) then default list
      const defaultList = data.find(l => l.is_default) || data[0]
      selectedListId.value = defaultList.id
    }
  }
  return data
}, {
  watch: [user]
})

// Fetch shopping list items with user profiles
const { data: listItems } = await useAsyncData('shopping-list', async () => {
  if (!selectedListId.value) return []
  const { data, error } = await supabase
    .from('list_items')
    .select(`
      *,
      user_profile!user_id (
        name
      )
    `)
    .eq('list_id', selectedListId.value)
  if (error) throw error
  return data
}, {
  watch: [user, selectedListId]
})

const sortedListItems = computed(() => {
  if (!listItems.value) return []
  return [...listItems.value].sort((a, b) => {
    const nameA = a.user_profile?.name || 'Anonymous'
    const nameB = b.user_profile?.name || 'Anonymous'
    return nameA.localeCompare(nameB)
  })
})

const groupedListItems = computed(() => {
  if (!sortedListItems.value) return {}
  const groups: Record<string, typeof sortedListItems.value> = {}

  // Sort groups by category name, putting 'Other' last
  const categoryOrder = categoryOptions.map(opt => opt.value)

  sortedListItems.value.forEach((item) => {
    const cat = item.category || 'Other'
    if (!groups[cat]) groups[cat] = []
    groups[cat].push(item)
  })

  // Return groups in specific order
  const orderedGroups: Record<string, typeof sortedListItems.value> = {}
  categoryOrder.forEach((cat) => {
    if (groups[cat]) {
      orderedGroups[cat] = groups[cat]
    }
  })

  // Add any categories not in categoryOptions (if any)
  Object.keys(groups).forEach((cat) => {
    if (!orderedGroups[cat]) {
      orderedGroups[cat] = groups[cat]
    }
  })

  return orderedGroups
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

async function addSuggestedItem(item: { id: number, name: string, category?: string }) {
  if (!selectedListId.value) return

  // Check if item is already in the list to prevent duplicates
  const isInList = listItems.value?.some(li => li.recurring_item_id === item.id)
  if (isInList) {
    toast.add({
      title: 'Info',
      description: `${item.name} is already in your list`,
      color: 'info'
    })
    return
  }

  try {
    const { error } = await supabase
      .from('list_items')
      .insert({
        name: item.name,
        user_id: user.value?.sub || null,
        recurring_item_id: item.id,
        quantity: 1,
        list_id: selectedListId.value,
        category: item.category || 'Other'
      })

    if (error) throw error

    toast.add({
      title: 'Success',
      description: `Added ${item.name} to list`,
      color: 'success'
    })

    // Refresh data
    await refreshNuxtData(['shopping-list', 'all-list-items'])
  } catch (error) {
    const err = error as { message?: string }
    toast.add({
      title: 'Error',
      description: err.message || 'Failed to add item',
      color: 'error'
    })
    console.error('Error adding suggested item:', error)
  }
}

async function deleteItem(id: number) {
  try {
    const { error } = await supabase
      .from('list_items')
      .delete()
      .eq('id', id)

    if (error) throw error
    checkedItems.value.delete(id)
    checkedItems.value = new Set(checkedItems.value)
    await refreshNuxtData(['shopping-list', 'all-list-items'])
  } catch (error) {
    console.error('Error deleting item:', error)
  }
}

async function markAsBought() {
  if (!listItems.value) return

  const itemsToProcess = checkedItems.value.size > 0
    ? listItems.value.filter(item => checkedItems.value.has(item.id))
    : listItems.value

  if (itemsToProcess.length === 0) return

  try {
    // 1. Update recurring items' last_bought field
    const recurringItemsToUpdate = itemsToProcess
      .filter(item => item.recurring_item_id)
      .map(item => item.recurring_item_id)

    if (recurringItemsToUpdate.length > 0) {
      const today = new Date().toISOString().split('T')[0]
      const { error: updateError } = await supabase
        .from('recurring_items')
        .update({ last_bought: today })
        .in('id', recurringItemsToUpdate)

      if (updateError) throw updateError
    }

    // 2. Delete items from list_items
    const idsToDelete = itemsToProcess.map(item => item.id)
    const { error: deleteError } = await supabase
      .from('list_items')
      .delete()
      .in('id', idsToDelete)

    if (deleteError) throw deleteError

    // 3. Cleanup and Refresh
    checkedItems.value.clear()
    await refreshNuxtData(['shopping-list', 'recurring-items', 'all-list-items'])
  } catch (error) {
    console.error('Error marking items as bought:', error)
  }
}

async function handleUpdateName() {
  if (editingId.value === null || !editName.value) return

  isUpdating.value = true
  try {
    const { error } = await supabase
      .from('recurring_items')
      .update({ name: editName.value })
      .eq('id', editingId.value)

    if (error) throw error

    toast.add({
      title: 'Success',
      description: 'Item updated successfully',
      color: 'success'
    })

    await refreshNuxtData('recurring-items')
    editingId.value = null
  } catch (error) {
    const err = error as { message?: string }
    toast.add({
      title: 'Error',
      description: err.message || 'Failed to update item',
      color: 'error'
    })
  } finally {
    isUpdating.value = false
  }
}

async function handleDeleteRecurringItem(id: number) {
  isDeleting.value = true
  try {
    const { error } = await supabase
      .from('recurring_items')
      .delete()
      .eq('id', id)

    if (error) throw error

    toast.add({
      title: 'Success',
      description: 'Item deleted successfully',
      color: 'success'
    })

    await refreshNuxtData('recurring-items')
    deletingId.value = null
  } catch (error) {
    const err = error as { message?: string }
    toast.add({
      title: 'Error',
      description: err.message || 'Failed to delete item',
      color: 'error'
    })
  } finally {
    isDeleting.value = false
  }
}

async function createList() {
  if (!newListName.value) return
  isCreatingList.value = true
  try {
    const { data, error } = await supabase
      .from('shopping_lists')
      .insert({
        name: newListName.value,
        is_default: (shoppingLists.value?.length || 0) === 0
      })
      .select()
      .single()

    if (error) throw error

    toast.add({
      title: 'Success',
      description: `Created list: ${newListName.value}`,
      color: 'success'
    })

    newListName.value = ''
    await refreshLists()
    selectedListId.value = data.id
  } catch (error) {
    const err = error as { message?: string }
    toast.add({
      title: 'Error',
      description: err.message || 'Failed to create list',
      color: 'error'
    })
  } finally {
    isCreatingList.value = false
  }
}

async function deleteList() {
  if (!selectedListId.value) return
  isDeletingList.value = true
  try {
    const { error } = await supabase
      .from('shopping_lists')
      .delete()
      .eq('id', selectedListId.value)

    if (error) throw error

    toast.add({
      title: 'Success',
      description: 'List deleted successfully',
      color: 'success'
    })

    selectedListId.value = null
    await refreshLists()
  } catch (error) {
    const err = error as { message?: string }
    toast.add({
      title: 'Error',
      description: err.message || 'Failed to delete list',
      color: 'error'
    })
  } finally {
    isDeletingList.value = false
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
          <!-- List Selection -->
          <div class="flex flex-col gap-2">
            <div class="flex items-center gap-2">
              <USelect
                v-model="selectedListId"
                :items="shoppingLists || []"
                label-key="name"
                value-key="id"
                placeholder="Select a list"
                class="flex-1"
              />
              <UPopover>
                <UButton icon="i-lucide-plus" variant="soft" color="neutral" />
                <template #content>
                  <div class="p-4 space-y-3 w-64">
                    <p class="text-sm font-medium">
                      Create New List
                    </p>
                    <UInput v-model="newListName" placeholder="List name" @keyup.enter="createList" />
                    <UButton
                      class="w-full"
                      :loading="isCreatingList"
                      :disabled="!newListName"
                      @click="createList"
                    >
                      Create
                    </UButton>
                  </div>
                </template>
              </UPopover>
              <UButton
                v-if="selectedListId"
                icon="i-lucide-trash-2"
                variant="soft"
                color="error"
                :loading="isDeletingList"
                @click="deleteList"
              />
            </div>

            <p v-if="itemsNotShownSummary" class="text-xs text-gray-500 px-1 italic">
              {{ itemsNotShownSummary }}
            </p>
          </div>

          <div v-if="!selectedListId" class="text-center py-10 text-gray-500">
            <p>
              Please select or create a shopping list to get started.
            </p>
          </div>

          <template v-else>
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
              <form @submit.prevent="addItem">
                <div class="grid grid-cols-12 gap-4 items-end">
                  <UFormField label="Item Name" class="col-span-12 sm:col-span-4">
                    <UInput v-model="newItemName" placeholder="e.g. Milk" class="w-full" />
                  </UFormField>

                  <UFormField label="Qty" class="col-span-4 sm:col-span-2">
                    <USelect
                      v-model="quantity"
                      :items="quantityOptions"
                      class="w-full"
                    />
                  </UFormField>

                  <UFormField label="Category" class="col-span-8 sm:col-span-4">
                    <USelect
                      v-model="selectedCategory"
                      :items="categoryOptions"
                      class="w-full"
                    />
                  </UFormField>

                  <div class="col-span-6 sm:col-span-2 flex items-center h-10 px-1">
                    <UCheckbox v-model="isRecurring" label="Recurring?" />
                  </div>

                  <UFormField v-if="isRecurring" label="Every (wks)" class="col-span-6 sm:col-span-2">
                    <UInput v-model="frequency" type="number" min="1" />
                  </UFormField>

                  <div :class="[isRecurring ? 'col-span-6 sm:col-span-2' : 'col-span-6 sm:col-span-2', 'flex justify-end']">
                    <UButton
                      type="submit"
                      icon="i-lucide-plus"
                      :loading="isSubmitting"
                      :disabled="!newItemName"
                      class="w-full sm:w-auto"
                    >
                      Add
                    </UButton>
                  </div>
                </div>
              </form>
            </UCard>

            <div v-if="listItems && listItems.length > 0" class="space-y-4">
              <div v-for="(items, category) in groupedListItems" :key="category" class="space-y-2">
                <h3 class="text-xs font-bold text-gray-400 uppercase tracking-widest px-2 pt-2">
                  {{ categoryOptions.find(opt => opt.value === category)?.label || category }}
                </h3>
                <UCard :ui="{ body: 'p-0' }">
                  <ul class="divide-y divide-gray-200 dark:divide-gray-800">
                    <li v-for="listItem in items" :key="listItem.id" class="p-3 flex items-center justify-between">
                      <div class="flex items-center gap-3">
                        <UCheckbox
                          :model-value="checkedItems.has(listItem.id)"
                          @update:model-value="(val) => {
                            if (val) {
                              checkedItems.add(listItem.id)
                            }
                            else {
                              checkedItems.delete(listItem.id)
                            }
                            // Trigger reactivity for the Set
                            checkedItems = new Set(checkedItems)
                          }"
                        />
                        <div class="flex flex-col">
                          <div class="flex items-center gap-2">
                            <span :class="{ 'line-through text-gray-400': checkedItems.has(listItem.id) }">
                              {{ listItem.name }}
                            </span>
                            <span class="text-xs text-gray-400">x{{ listItem.quantity }}</span>
                          </div>
                          <span class="text-[10px] text-gray-500">Added by: {{ listItem.user_profile?.name || 'Anonymous' }}</span>
                        </div>
                      </div>
                      <UButton
                        color="error"
                        variant="ghost"
                        icon="i-lucide-trash-2"
                        size="xs"
                        @click="deleteItem(listItem.id)"
                      />
                    </li>
                  </ul>
                </UCard>
              </div>

              <div class="flex justify-end pt-2">
                <UButton
                  icon="i-lucide-check-check"
                  @click="markAsBought"
                >
                  {{ checkedItems.size > 0 ? `Mark ${checkedItems.size} items bought` : 'Mark all as bought' }}
                </UButton>
              </div>
            </div>
          </template>
        </div>

        <!-- Recurring Items Tab -->
        <div v-else-if="item.value === 'recurring'" class="space-y-6 pt-4">
          <!-- List Selection -->
          <div class="flex flex-col gap-2">
            <div class="flex items-center gap-2">
              <USelect
                v-model="selectedListId"
                :items="shoppingLists || []"
                label-key="name"
                value-key="id"
                placeholder="Select a list"
                class="flex-1"
              />
              <UPopover>
                <UButton icon="i-lucide-plus" variant="soft" color="neutral" />
                <template #content>
                  <div class="p-4 space-y-3 w-64">
                    <p class="text-sm font-medium">
                      Create New List
                    </p>
                    <UInput v-model="newListName" placeholder="List name" @keyup.enter="createList" />
                    <UButton
                      class="w-full"
                      :loading="isCreatingList"
                      :disabled="!newListName"
                      @click="createList"
                    >
                      Create
                    </UButton>
                  </div>
                </template>
              </UPopover>
              <UButton
                v-if="selectedListId"
                icon="i-lucide-trash-2"
                variant="soft"
                color="error"
                :loading="isDeletingList"
                @click="deleteList"
              />
            </div>

            <p v-if="itemsNotShownSummary" class="text-xs text-gray-500 px-1 italic">
              {{ itemsNotShownSummary }}
            </p>
          </div>

          <div v-if="!selectedListId" class="text-center py-10 text-gray-500">
            <p>
              Please select or create a shopping list to get started.
            </p>
          </div>

          <template v-else>
            <div class="flex justify-between items-center px-2">
              <h2 class="text-lg font-semibold">
                My Recurring Items
              </h2>
            </div>

            <UCard :ui="{ body: 'p-0' }">
              <ul class="divide-y divide-gray-200 dark:divide-gray-800">
                <li v-for="recItem in myRecurringItems" :key="recItem.id" class="p-4">
                  <div class="flex items-center justify-between mb-1">
                    <div v-if="editingId === recItem.id" class="flex-1 flex items-center gap-2 mr-4">
                      <UInput
                        v-model="editName"
                        class="flex-1"
                        size="sm"
                        @keyup.enter="handleUpdateName"
                        @keyup.esc="editingId = null"
                      />
                      <div class="flex gap-1">
                        <UButton
                          icon="i-lucide-check"
                          size="sm"
                          color="success"
                          variant="ghost"
                          :loading="isUpdating"
                          @click="handleUpdateName"
                        />
                        <UButton
                          icon="i-lucide-x"
                          size="sm"
                          color="error"
                          variant="ghost"
                          @click="editingId = null"
                        />
                      </div>
                    </div>
                    <span v-else class="font-medium">{{ recItem.name }}</span>

                    <div v-if="editingId !== recItem.id" class="flex gap-2">
                      <div v-if="deletingId === recItem.id" class="flex items-center gap-1 bg-error-50 dark:bg-error-950/30 px-2 py-1 rounded-md">
                        <span class="text-xs font-medium text-error-600 dark:text-error-400 mr-1">Delete?</span>
                        <UButton
                          icon="i-lucide-check"
                          size="xs"
                          color="error"
                          variant="ghost"
                          :loading="isDeleting"
                          @click="handleDeleteRecurringItem(recItem.id)"
                        />
                        <UButton
                          icon="i-lucide-x"
                          size="xs"
                          color="neutral"
                          variant="ghost"
                          @click="deletingId = null"
                        />
                      </div>
                      <template v-else>
                        <UButton
                          icon="i-lucide-pencil"
                          size="sm"
                          variant="ghost"
                          color="neutral"
                          :disabled="deletingId !== null || editingId !== null"
                          @click="() => {
                            editingId = recItem.id
                            editName = recItem.name
                          }"
                        />
                        <UButton
                          icon="i-lucide-trash-2"
                          size="sm"
                          variant="ghost"
                          color="error"
                          :disabled="deletingId !== null || editingId !== null"
                          @click="deletingId = recItem.id"
                        />
                        <UButton
                          icon="i-lucide-shopping-cart"
                          size="sm"
                          variant="soft"
                          :label="listItems?.some(li => li.recurring_item_id === recItem.id) ? 'In List' : 'Add to List'"
                          :disabled="listItems?.some(li => li.recurring_item_id === recItem.id) || deletingId !== null || editingId !== null"
                          @click="addSuggestedItem(recItem)"
                        />
                      </template>
                    </div>
                  </div>
                  <div class="text-xs text-gray-500 flex gap-4">
                    <span>Every {{ recItem.frequency }} {{ recItem.frequency_type }}</span>
                    <span>Category: {{ categoryOptions.find(opt => opt.value === recItem.category)?.label || recItem.category || 'No Category' }}</span>
                    <span>Last: {{ recItem.last_bought ? formatDate(recItem.last_bought) : 'Never' }}</span>
                  </div>
                </li>
              </ul>
            </UCard>
          </template>
        </div>
      </template>
    </UTabs>
  </div>
</template>
