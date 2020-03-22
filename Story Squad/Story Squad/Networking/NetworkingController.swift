//
//  NetworkingController.swift
//  Story Squad
//
//  Created by Jonalynn Masters on 2/26/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import Firebase

class NetworkingController {
    
    // MARK: - Properties
    private let baseURL = URL(string: "https://story-squad.herokuapp.com")!
    
    var parentUser: Parent?
    var children: [Child]?
    var childUser: Child?
    
    var parentBearer: Bearer?
    var childBearer: Bearer?
    
    // MARK: - Save Parent Bearer in UserDefaults
    func saveParentBearer(bearer: Bearer, email: String, password: String) {
        
        UserDefaults.standard.set(bearer.token, forKey: .parentBearerString)
        UserDefaults.standard.set(email, forKey: .parentEmailString)
        UserDefaults.standard.set(password, forKey: .parentPassString)
    }
    
    // MARK: - Logout
    func logOut() {
        parentBearer = nil
        childBearer = nil
    }
    
    // MARK: - Create Parent using Server
    func updateParentWithServer(parent: Parent, completion: @escaping(Result<Parent?, NetworkingError>) -> Void) {
        
        guard let parentBearer = parentBearer else {
            completion(Result.failure(NetworkingError.noBearer))
            return
        }
        
        let registerURL = baseURL
            .appendingPathComponent("parents")
            .appendingPathComponent("me")
        
        var request = URLRequest(url: registerURL)
        
        request.httpMethod = HTTPMethod.get.rawValue
        //        request.setValue("application/json", forHTTPHeaderField: HeaderNames.contentType.rawValue)
        request.setValue("\(parentBearer.token)", forHTTPHeaderField: HeaderNames.authorization.rawValue)
        
        print("Request: \(request)")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                print("Error getting response: \(error)")
                completion(.failure(.serverError(error)))
                return
            }
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    print("Good 200 response")
                } else {
                    print("Bad response, code: \(response.statusCode)")
                    print("Response description: \(response.description)")
                    print("Response debug description: \(response.debugDescription)")
                    completion(.failure(.unexpectedStatusCode(response.statusCode)))
                    return
                }
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let dataString = String(data: data, encoding: .utf8)
                print("parent response as data: \(String(describing: dataString))")
                
                // Update in CoreData with ParentRepresentation
                let parentRep = try JSONDecoder().decode(ParentRepresentation.self, from: data)
                self.updateParentInCoreData(with: parentRep)

                completion(.success(self.parentUser))
                return
                
            } catch {
                print("Error decoding: \(error)")
                completion(.failure(.badDecode))
                return
            }
        }.resume()
    }
    
    // MARK: - Update a Child Account
    func updateChildAccountInServer(child: Child, username: String?, dyslexiaPreference: Bool?, grade: Int16?, completion: @escaping(Result<Child?, NetworkingError>) -> Void) {
        
        guard let parentBearer = parentBearer else {
            completion(Result.failure(NetworkingError.noBearer))
            return
        }
        
//        guard let id = child.id else { return }
        let id = child.id
        
        let registerURL = baseURL
            .appendingPathComponent("children")
            .appendingPathComponent("list")
            .appendingPathComponent("\(id)")
        
        guard let usernameString = username ?? child.username else { return completion(.failure(.noRepresentation))}
        let dyslexiaString = dyslexiaPreference ?? child.dyslexiaPreference
        let gradeString = grade ?? child.grade
        
        let json = """
        {
        "username": "\(usernameString)",
        "preferences": {
        "dyslexia": \(dyslexiaString)
        },
        "grade": \(gradeString)
        }
        """
        
        let jsonData = json.data(using: .utf8)
        
        guard let unwrappedData = jsonData else {
            print("encoded data wrong, couldn't unwrap data")
            completion(.failure(.formattedJSONIncorrectly))
            return
        }
        
        var request = URLRequest(url: registerURL)
        
        request.httpMethod = HTTPMethod.put.rawValue
        request.setValue("application/json", forHTTPHeaderField: HeaderNames.contentType.rawValue)
        request.setValue("\(parentBearer.token)", forHTTPHeaderField: HeaderNames.authorization.rawValue)
        request.httpBody = unwrappedData
        
        print("Request: \(request)")
        
        URLSession.shared.dataTask(with: request) { (data , response, error) in
            
            if let error = error {
                print("Error getting response: \(error)")
                completion(.failure(.serverError(error)))
                return
            }
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    print("Good 200 response")
                } else {
                    print("Bad response, code: \(response.statusCode)")
                    print("Response description: \(response.description)")
                    print("Response debug description: \(response.debugDescription)")
                    completion(.failure(.unexpectedStatusCode(response.statusCode)))
                    return
                }
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let dataString = String(data: data, encoding: .utf8)
                print("child Data from response: \(String(describing: dataString))")
                
                let childRep = try JSONDecoder().decode(ChildRepresentation.self, from: data)
                
                // Update this Child in CoreData with childRepresentation
                self.updateChildInCoreData(with: childRep)
                
                completion(.success(self.childUser))
                return
                
            } catch {
                print("Error decoding: \(error)")
                completion(.failure(.badDecode))
                return
            }
        }.resume()
    }
    
    // MARK: - Signup Parent Account
    func signupParent(email: String, password: String, termsOfService: Bool, name: String, completion: @escaping(Result<Bearer?, NetworkingError>) -> Void) {
        //        func signupParent(email: String, password: String, termsOfService: Bool,  completion: @escaping(Result<ParentRepresentation?, NetworkingError>) -> Void) {
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer undefined"
        ]
        let json = """
        {
        "email": "\(email)",
        "password": "\(password)",
        "termsOfService": true
        }
        """
        let jsonData = json.data(using: .utf8)
        
        let request = NSMutableURLRequest(url: NSURL(string: "https://story-squad.herokuapp.com/auth/register")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = jsonData!
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                completion(.failure(.serverError(error)))
                return
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse as Any)
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                // Decode the bearer
                let parentBearer = try JSONDecoder().decode(Bearer.self, from: data)
                self.parentBearer = parentBearer
                
                // Save Bearer in UserDefaults
                self.saveParentBearer(bearer: parentBearer, email: email, password: password)
                
                // Create Parent in CoreData
                let temporaryID = Int16.random(in: 0..<1_000)
                let temporaryPIN = Int16.random(in: 0..<1_000)
                self.createParent(name: name, id: temporaryID, email: email, password: password, pin: temporaryPIN)
                
                // Return the Bearer
                completion(.success(parentBearer))
                return
            } catch {
                print("Error decoding: \(error)")
                completion(.failure(.badDecode))
                return
            }
        })
        dataTask.resume()
    }
    
    //        func signupParent(email: String, password: String, termsOfService: Bool, name: String, completion: @escaping(Result<Bearer?, NetworkingError>) -> Void) {
    
    //          let registerURL = baseURL
    //                .appendingPathComponent("auth")
    //                .appendingPathComponent("register")
    //
    //            let json = """
    //            {
    //            "email": "\(email)",
    //            "password": "\(password)",
    //            "termsOfService": "\(termsOfService)"
    //            }
    //            """
    //
    //            let jsonData = json.data(using: .utf8)
    //
    //            guard let unwrappedData = jsonData else {
    //                print("encoded data wrong, couldn't unwrap data")
    //                completion(.failure(.formattedJSONIncorrectly))
    //                return
    //            }
    //
    //            var request = URLRequest(url: registerURL)
    //            request.httpMethod = HTTPMethod.post.rawValue
    //
    //            request.allHTTPHeaderFields = [
    //              "content-type": "application/json",
    //              "authorization": "Bearer undefined"
    //            ]
    //    //        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    //            request.httpBody = unwrappedData
    //            print("Request: \(request)")
    //
    //            URLSession.shared.dataTask(with: request) { (data, response, error) in
    //
    //                if let error = error {
    //                    print("Error getting response: \(error)")
    //                    completion(.failure(.serverError(error)))
    //                    return
    //                }
    //
    //                if let response = response as? HTTPURLResponse {
    //                    if response.statusCode == 200 {
    //                        print("Good 200 response")
    //                    } else {
    //                        print("Bad response, code: \(response.statusCode)")
    //                        print("\(response)")
    //                        completion(.failure(.unexpectedStatusCode(response.statusCode)))
    //                        return
    //                    }
    //                }
    //
    //                guard let data = data else {
    //                    completion(.failure(.noData))
    //                    return
    //                }
    //                do {
    //                    let dataString = String(data: data, encoding: .utf8)
    //                    print("response Parent data: \(String(describing: dataString))")
    //                    let parentRepresentation = try JSONDecoder().decode(ParentRepresentation.self, from: data)
    ////                    self.parentUser?.parentRepresentation = parentRepresentation
    //                    print("Parent Representation: \(parentRepresentation)")
    //
    //                    let bearer = try JSONDecoder().decode(Bearer.self, from: data)
    //                    self.bearer = bearer
    //                    completion(.success(parentRepresentation))
    //                    return
    //                } catch {
    //                    print("Error decoding: \(error)")
    //                    completion(.failure(.badDecode))
    //                    return
    //                }
    //            }.resume()
    //}
    
    // MARK: - Login Parent Account
    func loginParent(email: String, password: String, completion: @escaping(Result<Bearer?, NetworkingError>) -> Void) {
        
        let registerURL = baseURL
            .appendingPathComponent("auth")
            .appendingPathComponent("login")
        
        var request = URLRequest(url: registerURL)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = ["Content-Type": "application/json"]
        
        let json = """
        {
        "email": "\(email)",
        "password": "\(password)"
        }
        """
        
        let jsonData = json.data(using: .utf8)
        
        guard let unwrappedData = jsonData else {
            print("encoded data wrong, couldn't unwrap data")
            completion(.failure(.formattedJSONIncorrectly))
            return
        }
        request.httpBody = unwrappedData
        print("Request: \(request)")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                print("Error getting response: \(error)")
                completion(.failure(.serverError(error)))
                return
            }
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    print("Good 200 response")
                } else {
                    print("Bad response, code: \(response.statusCode)")
                    completion(.failure(.unexpectedStatusCode(response.statusCode)))
                    return
                }
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                // Decoding Bearer
                let parentBearer = try JSONDecoder().decode(Bearer.self, from: data)
                self.parentBearer = parentBearer
                
                // Save Bearer in UserDefaults
                self.saveParentBearer(bearer: parentBearer, email: email, password: password)
                
                // Fetching parent from CD, or create a new managed parent
                // Either way, assigns managed object to self.parentUser
                // (Object is fetched/created on main context so safe to use in
                // view controllers
                self.fetchOrCreateParent(with: email, password: password) {
                
                    // Return the Bearer
                    completion(.success(self.parentBearer))
                }
            } catch {
                print("Error decoding: \(error)")
                completion(.failure(.badDecode))
                return
            }
        }.resume()
    }
    
    // MARK: - Parent CRUD Methods
    
    // Create Parent
    func createParent(name: String, id: Int16, email: String, password: String, pin: Int16, completion: @escaping(() -> Void ) = {}) {
        
        DispatchQueue.main.async {
            let moc = CoreDataStack.shared.mainContext
            self.parentUser = Parent(name: name, id: id, email: email, password: password, pin: pin, context: moc)
            
            // Saving to CoreData
            CoreDataStack.shared.save(context: moc)
            completion()
        }
    }
    
    // Update Parent
    func updateParent(name: String?, id: Int16, email: String?, pin: Int16?, password: String?, context: NSManagedObjectContext) {
        
        guard let parent = fetchParentFromCD(with: id) else { return }
        
        // Use new property or old property
        let newName = name ?? parent.name
        let newEmail = email ?? parent.email
        let newPin = pin ?? parent.pin
        let newPassword = password ?? parent.password
        
        let moc = CoreDataStack.shared.mainContext
        let fetchRequest: NSFetchRequest<Parent> = Parent.fetchRequest()
        
        // Array with parent that needs to be fetched
        let parentsByID = [id]
        fetchRequest.predicate = NSPredicate(format: "id IN %@", parentsByID)
        
        // Trying to fetch array of parents
        let fetchedParents = try? moc.fetch(fetchRequest)
        guard let parents = fetchedParents else { return }
        
        for parent in parents {
            
            // Updating Parent
            if parent.id == id {
                parent.name = newName
                parent.email = newEmail
                parent.password = newPassword
                parent.pin = newPin
                
                print("Succefully fetched and updated parent in CoreData")
            } else {
                NSLog("Couldn't fetched and update parent in CoreData")
            }
        }
        
        // Saving to CoreData
        CoreDataStack.shared.save(context: context)
    }
    
    // Delete Parent
    func deleteParentFromCoreData(parent: Parent, context: NSManagedObjectContext) {
        context.performAndWait {
            context.delete(parent)
            CoreDataStack.shared.save(context: context)
        }
    }
    
    // MARK: - Update using Representations
    
    // Parent
    private func updateParentInCoreData(with representation: ParentRepresentation) {
        
        guard let parentUser = parentUser else { return }
        
        parentUser.id = representation.id
        parentUser.email = representation.email
        
        CoreDataStack.shared.save(context: CoreDataStack.shared.mainContext)
        
        self.parentUser = parentUser
    }
    
    // Child
    private func updateChildInCoreData(with representation: ChildRepresentation) {
        
        guard let childUser = childUser else { return }
        
        childUser.username = representation.username
        //        childUser.id = representation.id
        childUser.grade = representation.grade
        childUser.avatar = representation.avatar
        childUser.dyslexiaPreference = representation.dyslexiaPreference
        
        CoreDataStack.shared.save(context: CoreDataStack.shared.mainContext)
        
        self.childUser = childUser
    }
    
    // MARK: - Child CRUD Methods
    
    // create Child
    func createChildAndAddToParent(parent: Parent, name: String, username: String?, id: Int16?, pin: Int16, grade: Int16, cohort: String?, dyslexiaPreference: Bool = false, avatar: String?, context: NSManagedObjectContext) {
        
        // Generate random avatar
        let arrayOfAvatars = ["Hero 6.png", "Hero 11.png", "Hero 12.png", "Hero 13.png", "Hero 14.png", "Hero 15.png", "Hero 16.png", "Hero 18.png", "Hero 19.png"]
        
        let randomAvatar = arrayOfAvatars.randomElement()
        
        // generate random ID
        let temporaryID = Int16.random(in: 0..<1_000)
        
        //        let randomID = Int16.random(in: 1..<1000)
        
        // swiftlint:disable:next line_length
        let child = Child(name: name, id: temporaryID, username: username, parent: parent, pin: pin, grade: grade, cohort: cohort, dyslexiaPreference: dyslexiaPreference, avatar: randomAvatar, context: context)
        
        // Adding child to it's parent in Core Data
        parent.addToChildren(child)
        CoreDataStack.shared.save(context: context)
    }
    
    // Update Child
    // swiftlint:disable:next function_parameter_count
    func updateChildInCoreDataWith(name: String?, id: Int16, username: String?, pin: Int16?, grade: Int16?, cohort: String?, dyslexiaPreference: Bool?, avatar: String?, context: NSManagedObjectContext) {
        
        guard let child = fetchChildFromCD(with: id) else { return }
        
        // Use new property or old property
        let newName = name ?? child.name
        let newUsername = username ?? child.username
        let newPin = pin ?? child.pin
        let newGrade = grade ?? child.grade
        let newCohort = cohort ?? child.cohort
        let newDyslexiaPreference = dyslexiaPreference ?? child.dyslexiaPreference
        let newAvatar = avatar ?? child.avatar
        
        let moc = CoreDataStack.shared.mainContext
        let fetchRequest: NSFetchRequest<Child> = Child.fetchRequest()
        
        // Array with child that needs to be fetched
        let childrenByID = [id]
        fetchRequest.predicate = NSPredicate(format: "id IN %@", childrenByID)
        
        // Trying to fetch array of children
        let fetchedChildren = try? moc.fetch(fetchRequest)
        
        guard let children = fetchedChildren else { return }
        for child in children {
            
            // Updating Child
            if child.id == id {
                child.name = newName
                child.username = newUsername
                child.pin = newPin
                child.grade = newGrade
                child.cohort = newCohort
                child.dyslexiaPreference = newDyslexiaPreference
                child.avatar = newAvatar
                
                print("Succefully fetched and updated child \(String(describing: name)) in CoreData")
            } else {
                NSLog("Couldn't fetched and update child \(String(describing: name)) in CoreData")
            }
        }
        
        // Saving to CoreData
        CoreDataStack.shared.save(context: context)
    }
    
    // Delete Child
    func deleteChildFromCoreData(child: Child, context: NSManagedObjectContext) {
        
        context.performAndWait {
            context.delete(child)
            CoreDataStack.shared.save(context: context)
        }
    }
    
    // MARK: - Fetch From CoreData
    
    // Parent
    func fetchParentFromCD(with id: Int16) -> Parent? {
        
        let moc = CoreDataStack.shared.mainContext
        let fetchRequest: NSFetchRequest<Parent> = Parent.fetchRequest()
        let parentsByID = [id]
        fetchRequest.predicate = NSPredicate(format: "id IN %@", parentsByID)
        
        let possibleParents = try? moc.fetch(fetchRequest)
        
        guard let parents = possibleParents else { return nil }
        for parent in parents {
            
            if parent.id == id {
                self.parentUser = parent
            } else {
                print("Couldn't fetch parent from CoreData")
            }
        }
        return parentUser
    }
    
    func fetchOrCreateParent(with email: String, password: String, completion: @escaping(() -> Void) = {}) {
        
        DispatchQueue.main.async {
            var parent: Parent?
            let moc = CoreDataStack.shared.mainContext
            let fetchRequest: NSFetchRequest<Parent> = Parent.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "email == %@", email)
            
            do {
                parent = try moc.fetch(fetchRequest).first
            } catch {
                NSLog("Parent wasn't fetched from CoreData")
                completion()
                // handle the fetch error
            }
            
            if let parent = parent {
//                self.updateParentWithServer(parent: parent) { (result) in
//                    do {
//                        let parent = try result.get()
////                        self.parentUser = parent
//                        print("\nUpdated Parent with Server\n")
//                        completion()
//                    } catch {
//                        NSLog("\nCouldn't update Parent with Server\n")
//                        completion()
//                    }
//                }
                self.parentUser = parent
                completion()
            } else {
                let temporaryID = Int16.random(in: 0..<1_000)
                let temporaryPIN = Int16.random(in: 0..<1_000)
                self.createParent(name: "", id: temporaryID, email: email, password: password, pin: temporaryPIN, completion: completion)
            }
        }
    }
    
    func fetchParentFromCDWithEmail(email: String) -> Parent? {
        
        let moc = CoreDataStack.shared.mainContext
        let fetchRequest: NSFetchRequest<Parent> = Parent.fetchRequest()
        let parentsByEmail = [email]
        fetchRequest.predicate = NSPredicate(format: "email IN %@", parentsByEmail)
        
        let possibleParents = try? moc.fetch(fetchRequest)
        
        guard let parents = possibleParents else { return nil }
        for parent in parents {
            
            if parent.email == email {
                self.parentUser = parent
            } else {
                print("Couldn't fetch parent from CoreData")
            }
        }
        return parentUser
    }
    
    // Child
    func fetchChildFromCD(with id: Int16) -> Child? {
        
        let moc = CoreDataStack.shared.mainContext
        let fetchRequest: NSFetchRequest<Child> = Child.fetchRequest()
        let childrenByID = [id]
        fetchRequest.predicate = NSPredicate(format: "id IN %@", childrenByID)
        
        let possibleChildren = try? moc.fetch(fetchRequest)
        
        guard let children = possibleChildren else { return nil }
        for child in children {
            
            if child.id == id {
                self.childUser = child
            } else {
                print("Couldn't fetch child from CoreData")
            }
        }
        return childUser
    }
    
    // Children
    func fetchChildrenFromCDFor(parent: Parent) -> [Child] {
        
        let moc = CoreDataStack.shared.mainContext
        let fetchRequest: NSFetchRequest<Child> = Child.fetchRequest()

        let predicate = NSPredicate(format: "parent.id == %i", parentUser?.id ?? 0)
        fetchRequest.predicate = predicate
        
        let fetchedChildren = try? moc.fetch(fetchRequest)
        
        guard let children = fetchedChildren else { return [] }

        return children
    }
}
