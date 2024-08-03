//
//  FetchController.swift
//  Dex3
//
//  Created by Bayu P Yuhartono on 04/08/24.
//

import Foundation

struct FetchController {
    enum NetwotkError: Error {
        case badURL, badResponse, badData
    }
    
    private let baseURL = URL(string: "https://pokapi.co/api/v2/pokemon/")!
    
    func fetchAllPokemon() async throws -> [TempPokemon] {
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
}
