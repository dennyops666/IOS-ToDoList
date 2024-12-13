import Foundation
import CoreData

class CoreDataManager {
    
    // MARK: - Properties
    var context: NSManagedObjectContext!
    
    // MARK: - Task Operations
    
    func createTask(title: String, notes: String = "", dueDate: Date? = nil) -> Task {
        let task = Task(context: context)
        task.title = title
        task.notes = notes
        task.dueDate = dueDate
        task.createdAt = Date()
        task.isCompleted = false
        saveContext()
        return task
    }
    
    func fetchTasks(category: Category? = nil, includeCompleted: Bool = true) -> [Task] {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        var predicates: [NSPredicate] = []
        
        // 根据分类筛选
        if let category = category {
            predicates.append(NSPredicate(format: "category == %@", category))
        }
        
        // 根据完成状态筛选
        if !includeCompleted {
            predicates.append(NSPredicate(format: "isCompleted == NO"))
        }
        
        // 组合谓词
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        // 排序规则：优先级（降序）-> 截止日期（升序）-> 创建时间（降序）
        let prioritySort = NSSortDescriptor(key: "priority", ascending: false)
        let dueDateSort = NSSortDescriptor(key: "dueDate", ascending: true)
        let createdAtSort = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest.sortDescriptors = [prioritySort, dueDateSort, createdAtSort]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }
    
    func deleteTask(_ task: Task) {
        context.delete(task)
        saveContext()
    }
    
    // MARK: - Category Operations
    
    func createCategory(name: String) -> Category {
        let category = Category(context: context)
        category.name = name
        category.createdAt = Date()
        saveContext()
        return category
    }
    
    func fetchCategories() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        do {
            let categories = try context.fetch(request)
            // 为没有创建时间的分类设置创建时间
            for category in categories {
                if category.createdAt == nil {
                    category.createdAt = Date()
                }
            }
            if context.hasChanges {
                try context.save()
            }
            return categories
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    func deleteCategory(_ category: Category) {
        context.delete(category)
        saveContext()
    }
    
    func isCategoryNameExists(_ name: String) -> Bool {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Error checking category name: \(error)")
            return false
        }
    }
    
    // MARK: - Core Data Saving Support
    
    func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
