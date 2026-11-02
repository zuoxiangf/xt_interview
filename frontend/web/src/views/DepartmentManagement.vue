<template>
  <div class="department-management">
    <div class="page-header">
      <el-button type="primary" :icon="Plus" @click="openCreateDialog">
        添加部门
      </el-button>
      <el-button :icon="Refresh" @click="loadDepartments">刷新</el-button>
    </div>

    <el-form :inline="true" class="search-bar" @submit.prevent>
      <el-form-item label="关键字">
        <el-input
          v-model="searchForm.keyword"
          placeholder="部门名称 / 编码"
          clearable
          style="width: 200px"
          @keyup.enter="handleSearch"
        />
      </el-form-item>
      <el-form-item label="状态">
        <el-select
          v-model="searchForm.status"
          placeholder="全部"
          clearable
          style="width: 120px"
        >
          <el-option label="启用" :value="1" />
          <el-option label="禁用" :value="0" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" :icon="Search" @click="handleSearch">搜索</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>

    <el-table
      v-loading="loading"
      :data="pagedDepartments"
      border
      stripe
      style="width: 100%"
    >
      <el-table-column prop="name" label="部门名称" min-width="140" />
      <el-table-column prop="code" label="部门编码" min-width="120" />
      <el-table-column label="描述" min-width="220">
        <template #default="{ row }">
          {{ row.description || '-' }}
        </template>
      </el-table-column>
      <el-table-column label="状态" min-width="90">
        <template #default="{ row }">
          <el-tag :type="row.status === 1 ? 'success' : 'danger'">
            {{ row.status === 1 ? '启用' : '禁用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="创建时间" min-width="180">
        <template #default="{ row }">
          {{ formatTime(row.createTime) }}
        </template>
      </el-table-column>
      <el-table-column label="操作" width="160" fixed="right">
        <template #default="{ row }">
          <el-button type="primary" link :icon="Edit" @click="openEditDialog(row)">
            编辑
          </el-button>
          <el-button type="danger" link :icon="Delete" @click="handleDelete(row)">
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <div class="pagination-bar">
      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="pageSize"
        :total="filteredList.length"
        :page-sizes="[5, 10, 20, 50]"
        layout="total, sizes, prev, pager, next, jumper"
        background
        @size-change="handleSizeChange"
        @current-change="handlePageChange"
      />
    </div>

    <el-dialog
      v-model="dialogVisible"
      :title="isEdit ? '编辑部门' : '添加部门'"
      width="500px"
      @close="resetForm"
    >
      <el-form
        ref="formRef"
        :model="formData"
        :rules="formRules"
        label-width="90px"
      >
        <el-form-item label="部门名称" prop="name">
          <el-input v-model="formData.name" placeholder="请输入部门名称" />
        </el-form-item>
        <el-form-item label="部门编码" prop="code">
          <el-input v-model="formData.code" placeholder="请输入部门编码" />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input
            v-model="formData.description"
            type="textarea"
            :rows="3"
            placeholder="请输入部门描述"
          />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="formData.status" placeholder="请选择状态" style="width: 100%">
            <el-option label="启用" :value="1" />
            <el-option label="禁用" :value="0" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">
          确定
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { departmentApi } from '@/api'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete, Refresh, Search } from '@element-plus/icons-vue'
import type { FormInstance, FormRules } from 'element-plus'

const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const isEdit = ref(false)
const editId = ref<number>(0)

const departments = ref<any[]>([])

// 搜索条件（后端无分页/查询接口，采用前端过滤）
const searchForm = reactive({
  keyword: '',
  status: null as number | null
})

// 分页状态（前端分页）
const currentPage = ref(1)
const pageSize = ref(10)

const formRef = ref<FormInstance>()

const formData = reactive({
  name: '',
  code: '',
  description: '',
  status: 1
})

const formRules: FormRules = {
  name: [{ required: true, message: '请输入部门名称', trigger: 'blur' }],
  code: [{ required: true, message: '请输入部门编码', trigger: 'blur' }],
  status: [{ required: true, message: '请选择状态', trigger: 'change' }]
}

// 关键字 + 状态过滤后的列表
const filteredList = computed(() => {
  const kw = searchForm.keyword.trim().toLowerCase()
  return departments.value.filter((item) => {
    const matchKw =
      !kw ||
      (item.name || '').toLowerCase().includes(kw) ||
      (item.code || '').toLowerCase().includes(kw)
    const matchStatus = searchForm.status === null || item.status === searchForm.status
    return matchKw && matchStatus
  })
})

// 当前页数据
const pagedDepartments = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredList.value.slice(start, start + pageSize.value)
})

function formatTime(value: string): string {
  if (!value) return '-'
  return value.replace('T', ' ').slice(0, 19)
}

async function loadDepartments() {
  loading.value = true
  try {
    const res: any = await departmentApi.getAll()
    departments.value = res || []
  } catch (error: any) {
    ElMessage.error(error.message || '加载部门列表失败')
  } finally {
    loading.value = false
  }
}

function handleSearch() {
  currentPage.value = 1
}

function handleReset() {
  searchForm.keyword = ''
  searchForm.status = null
  currentPage.value = 1
}

function handleSizeChange() {
  currentPage.value = 1
}

function handlePageChange() {
  // 前端分页，pagedDepartments 依赖 currentPage 自动更新
}

function resetForm() {
  formData.name = ''
  formData.code = ''
  formData.description = ''
  formData.status = 1
  isEdit.value = false
  editId.value = 0
  formRef.value?.resetFields()
}

function openCreateDialog() {
  resetForm()
  dialogVisible.value = true
}

function openEditDialog(row: any) {
  resetForm()
  isEdit.value = true
  editId.value = row.id
  formData.name = row.name
  formData.code = row.code
  formData.description = row.description || ''
  formData.status = row.status
  dialogVisible.value = true
}

async function handleSubmit() {
  if (!formRef.value) return
  await formRef.value.validate(async (valid) => {
    if (!valid) return

    submitting.value = true
    try {
      const data = { ...formData }
      if (isEdit.value) {
        await departmentApi.update(editId.value, data)
        ElMessage.success('部门更新成功')
      } else {
        await departmentApi.create(data)
        ElMessage.success('部门创建成功')
      }
      dialogVisible.value = false
      await loadDepartments()
    } catch (error: any) {
      ElMessage.error(error.message || '操作失败')
    } finally {
      submitting.value = false
    }
  })
}

async function handleDelete(row: any) {
  try {
    await ElMessageBox.confirm(
      `确定要删除部门 "${row.name}" 吗？`,
      '删除确认',
      {
        confirmButtonText: '确定删除',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    await departmentApi.delete(row.id)
    ElMessage.success('部门删除成功')
    // 若删的是当前页最后一条且不是第一页，回退一页
    if (pagedDepartments.value.length === 1 && currentPage.value > 1) {
      currentPage.value -= 1
    }
    await loadDepartments()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '删除失败')
    }
  }
}

onMounted(() => {
  loadDepartments()
})
</script>

<style scoped>
.department-management {
  background: #fff;
  border-radius: 8px;
  padding: 20px;
}

.page-header {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
}

.search-bar {
  margin-bottom: 8px;
}

.pagination-bar {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}
</style>
