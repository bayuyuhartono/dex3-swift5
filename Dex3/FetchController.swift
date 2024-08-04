//
//  FetchController.swift
//  Dex3
//
//  Created by Bayu P Yuhartono on 04/08/24.
//

import Foundation
import CoreData

struct FetchController {
    enum NetwotkError: Error {
        case badURL, badResponse, badData
    }
    
    private let baseURL = URL(string: "https://pokeapi.co/api/v2/pokemon/")!
    
    func fetchAllPokemon() async throws -> [TempPokemon]? {
        if havePokemon() {
            return nil
        }
        
        var allPokemon: [TempPokemon] = []
        
        var fetchComponent = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        fetchComponent?.queryItems = [URLQueryItem(name: "limit", value: "386")]
        
        guard let fetchURL = fetchComponent?.url else {
            throw NetwotkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: fetchURL)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw NetwotkError.badResponse
        }
        
        guard let pokeDictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any], let pokeDex = pokeDictionary["results"] as? [[String: String]] else {
            throw NetwotkError.badData
        }
        
        for pokemon in pokeDex {
            if let url = pokemon["url"] {
                allPokemon.append(try await fetchPokemon(from: URL(string: url)!))
            }
        }
        
        return allPokemon
    }
    
    private func fetchPokemon(from url: URL) async throws -> TempPokemon {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw NetwotkError.badResponse
        }
        
        let tempPokemon = try JSONDecoder().decode(TempPokemon.self, from: data)
        
        print("Fetched \(tempPokemon.id): \(tempPokemon.name)")
        
        return tempPokemon
    }
    
    private func havePokemon() -> Bool {
        let context = PersistenceController.shared.container.newBackgroundContext()
        
        let fetchRequest: NSFetchRequest<Pokemon> = Pokemon.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id IN %@", [1, 386])
        
        do {
            let checkPokemon = try context.fetch(fetchRequest)
            
            if checkPokemon.count == 2 {
                return true
            }
        } catch {
            print("Fetch failed: \(error)")
            return false
        }
        
        return false
    }
}
