-- ==================== 用户-部门关联 ====================
-- 给 sys_account 表新增 department_id 字段（BIGINT, 可空, 外键关联 sys_department.id）
ALTER TABLE `sys_account`
    ADD COLUMN `department_id` BIGINT DEFAULT NULL COMMENT '部门ID' AFTER `password`;

-- 外键关联 sys_department.id（删除部门时置空，避免约束冲突）
ALTER TABLE `sys_account`
    ADD CONSTRAINT `fk_account_department`
    FOREIGN KEY (`department_id`) REFERENCES `sys_department` (`id`)
    ON DELETE SET NULL;

-- 部门ID索引，加速按部门查询
CREATE INDEX `idx_account_department` ON `sys_account` (`department_id`);
