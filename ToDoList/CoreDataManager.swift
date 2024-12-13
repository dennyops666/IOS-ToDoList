import CoreData
import UIKit

public final class CoreDataManager {
    public static let shared = CoreDataManager()
    
    private let coreDataStack: CoreDataStack
    
    public init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    public var viewContext: NSManagedObjectContext {
        coreDataStack.context
    }
    
    // MARK: - Task Operations
    public func createTask(
        title: String,
        notes: String?,
        dueDate: Date?,
        priority: TaskPriority = .medium,
        category: Category? = nil
    ) -> Task {
        let task = Task(context: viewContext)
        task.title = title
        task.notes = notes
        task.dueDate = dueDate
        task.createdAt = Date()
        task.priority = priority.rawValue
        task.category = category
        task.isCompleted = false
        save()
        return task
    }
    
    public func deleteTask(_ task: Task) {
        viewContext.delete(task)
        save()
    }
    
    public func updateTask(_ task: Task) {
        save()
    }
    
    public func fetchTasks() -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
    
    // MARK: - Category Operations
    public func createCategory(name: String, color: String = "#000000") -> Category {
        guard !isCategoryNameExists(name) else { return fetchCategories().first(where: { $0.name == name })! }
        
        let category = Category(context: viewContext)
        category.name = name
        category.color = color
        save()
        return category
    }
    
    public func deleteCategory(_ category: Category) {
        viewContext.delete(category)
        save()
    }
    
    public func updateCategory(_ category: Category) {
        save()
    }
    
    public func fetchCategories() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    public func updateCategoryRelationships(_ category: Category) {
        _ = category.tasks?.count
        save()
    }
    
    // MARK: - Helper Methods
    public func isCategoryNameExists(_ name: String) -> Bool {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let count = try viewContext.count(for: request)
            return count > 0
        } catch {
            print("Error checking category name: \(error)")
            return false
        }
    }
    
    public func getTaskCount(for category: Category) -> Int {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        
        do {
            let count = try viewContext.count(for: request)
            return count
        } catch {
            print("Error getting task count: \(error)")
            return 0
        }
    }
    
    // MARK: - Private Methods
    private func save() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}
