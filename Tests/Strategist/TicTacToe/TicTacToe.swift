//
//  TicTacToe.swift
//  MiniMaxTests
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

import Strategist

enum TicTacToePlayer: Strategist.Player {
    case X
    case O
}

extension TicTacToePlayer: CustomStringConvertible {
    var description: String {
        switch self {
        case .X: return "X"
        case .O: return "O"
        }
    }
}

extension TicTacToePlayer: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .X: return "Max"
        case .O: return "Min"
        }
    }
}

enum TicTacToeTile {
    case Empty
    case Occupied(TicTacToePlayer)

    var player: TicTacToePlayer? {
        switch self {
        case .Empty: return nil
        case let .Occupied(player): return player
        }
    }

    init(player: TicTacToePlayer?) {
        if let player = player {
            self = .Occupied(player)
        } else {
            self = .Empty
        }
    }
}

extension TicTacToeTile: Hashable {
    var hashValue: Int {
        switch self {
        case Empty:
            return 0
        case Occupied(let player):
            return player.hashValue
        }
    }
}

extension TicTacToeTile: Equatable {}

func ==(lhs: TicTacToeTile, rhs: TicTacToeTile) -> Bool {
    switch (lhs, rhs) {
    case (.Empty, .Empty): return true
    case let (.Occupied(playerLhs), .Occupied(playerRhs)): return playerLhs == playerRhs
    default: return false
    }
}

extension TicTacToeTile: CustomStringConvertible {
    var description: String {
        switch self {
        case .Empty: return " "
        case let .Occupied(player): return "\(player)"
        }
    }
}

struct TicTacToeMove {
    let index: Int
    let player: TicTacToePlayer
}

extension TicTacToeMove: CustomStringConvertible {
    var description: String {
        return "\(self.index)"
    }
}

extension TicTacToeMove: Strategist.Move {
    var hashValue: Int {
        return index
    }
}

extension TicTacToeMove: Equatable {}

func ==(lhs: TicTacToeMove, rhs: TicTacToeMove) -> Bool {
    return (lhs.index == rhs.index)
}

/// The objective of this game is to be the first to make three marks
/// in a horizontal, vertical, or diagonal row by placing marks on a 3x3 grid
/// alternating between the two playing players turn by turn.
struct TicTacToeGame: Strategist.Game {
    typealias Player = TicTacToePlayer
    typealias Move = TicTacToeMove
    typealias Score = Double

    let board: [TicTacToeTile]
    let players: [TicTacToePlayer]
    let playerIndex: UInt8

    var currentPlayer: Player {
        return self.players[Int(self.playerIndex)]
    }

    init(players: [TicTacToePlayer]) {
        assert(players.count == 2)
        assert(players[0] != players[1])
        self.board = [TicTacToeTile](count: 9, repeatedValue: .Empty)
        self.players = players
        self.playerIndex = 0
    }

    private init(board: [TicTacToeTile], players: [TicTacToePlayer], playerIndex: UInt8) {
        assert(board.count == 9)
        assert(players.count == 2)
        assert(playerIndex < 2)
        self.board = board
        self.players = players
        self.playerIndex = playerIndex
    }

    func update(move: Move) -> TicTacToeGame {
        var board = self.board
        board[move.index] = TicTacToeTile(player: move.player)
        let players = self.players
        let playerIndex = (self.playerIndex + 1) % 2
        return TicTacToeGame(board: board, players: players, playerIndex: playerIndex)
    }

    func isFinished() -> Bool {
        return self.board.reduce(true) { $0 && $1 != .Empty }
    }

    func playerAfter(player: Player) -> Player {
        guard let index = self.players.indexOf(player) else {
            fatalError("Unknown player: \(player)")
        }
        return self.players[(index + 1) % 2]
    }

    func playersAreAllied(players: (Player, Player)) -> Bool {
        return players.0 == players.1
    }

    func availableMoves() -> AnyGenerator<Move> {
        let lazyMap = self.board.enumerate().lazy.flatMap { index, tile in
            return (tile == .Empty) ? TicTacToeMove(index: index, player: self.currentPlayer) : nil
        }
        return AnyGenerator(lazyMap.generate())
    }

    func evaluate(forPlayer player: Player) -> Evaluation<Score> {
        var score = 0
        var occupied = 0
        let triples = TicTacToeGame.triples()
        for (a, b, c) in triples {
            let occupants = [self.board[a], self.board[b], self.board[c]].flatMap { $0.player }
            var playerOccupied = 0
            var opponentOccupied = 0
            for occupant in occupants {
                if occupant == player {
                    playerOccupied += 1
                } else {
                    opponentOccupied += 1
                }
                occupied += 1
            }
            if playerOccupied == 3 {
                return .Victory(0.0)
            } else if opponentOccupied == 3 {
                return .Defeat(0.0)
            }
            score += playerOccupied - opponentOccupied
        }
        if occupied == triples.count * 3 {
            return .Draw(0.0)
        }
        return .Ongoing(Double(score))
    }

    static func triples() -> [(Int, Int, Int)] {
        struct Holder {
            static let triplesArray = [
                (0, 1, 2), // top row
                (3, 4, 5), // center row
                (6, 7, 8), // bottom row
                (0, 3, 6), // left column
                (1, 4, 7), // center column
                (2, 5, 8), // right column
                (0, 4, 8), // tl-to-br diagonal
                (2, 4, 6), // tr-to-bl diagonal
            ]
        }
        return Holder.triplesArray
    }
}

func ==(lhs: TicTacToeGame, rhs: TicTacToeGame) -> Bool {
    guard lhs.board == rhs.board else {
        return false
    }
    guard lhs.players == rhs.players else {
        return false
    }
    guard lhs.playerIndex == rhs.playerIndex else {
        return false
    }
    return true
}

//extension TicTacToeGame: Hashable {
//    var hashValue: Int {
//        return self.board.enumerate().reduce(0) { hash, tuple in
//            let (index, tile) = tuple
//            return hash ^ index ^ tile.hashValue
//        }
//    }
//}

extension TicTacToeGame: CustomStringConvertible {
    var description: String {
        let board = [self.board[0...2], self.board[3...5], self.board[6...8]].map { row in
            row.map { "\($0)" }.joinWithSeparator(" | ")
            }.joinWithSeparator("\n")
        return "\(self.currentPlayer):\n\(board)"
    }
}