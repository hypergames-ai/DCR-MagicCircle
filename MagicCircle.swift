// MagicCircle.swift — the two containers and their two layers, as types; worlds founded inside
// worlds; now with rank, secrecy, and signs.
// Run as a script: swift MagicCircle.swift
//
//   magic circle = play space (rules, moves: Huizinga) + transitional space (gestures: Winnicott)
//   world        = transactional space (things, walls)  + space of appearance (deeds, words: Arendt)
//
// Rank lands on the world's two layers: a degree is conferred and indelible (a trace), an office
// is held and vacated (a thing). Secrecy comes in two kinds: graded disclosure of content
// (esoteric) and a founding withheld from the parent's ledger (secret). A sign has no meaning
// field; its value is its distribution.

import Foundation

// MARK: - People

/// Persona: the mask the voice sounds through. Note what is *not* here: a `who`, a rank, a
/// currency. All three are read off a world's ledger, and they differ from world to world.
struct Person: Hashable, CustomStringConvertible {
    let name: String
    init(_ name: String) { self.name = name }
    var description: String { name }
}

// MARK: - Play space (Huizinga): the structural layer of the circle

/// A move is addressed to the game state, not to the players as persons.
struct Move: Hashable {
    let by: Person
    let token: String
}

/// What a licensed rupture can confer: a degree (indelible) or an office (held).
enum Conferral {
    case degree(Int)
    case office(String)
}

/// A closed set of admissible moves, plus what the rules anticipate about their own refusal.
struct Rules {
    let name: String
    private let base: (Move) -> Bool
    private(set) var houseRules: Set<String> = []
    /// Refusals the rules themselves license: the fool, the carnival king, "I quit".
    /// Turner's liminal — a scheduled breaking the circle contains. It never founds anything.
    private let licensedRefusals: Set<String>
    /// Licensed refusals that change the refuser's standing in the hosting world: the rite of
    /// passage. The candidate dies to the old status and is reincorporated at a new one.
    let rites: [String: Conferral]

    init(name: String, licensedRefusals: Set<String> = [], rites: [String: Conferral] = [:],
         admits: @escaping (Move) -> Bool) {
        self.name = name
        self.licensedRefusals = licensedRefusals.union(rites.keys)
        self.rites = rites
        self.base = admits
    }

    func admits(_ move: Move) -> Bool { base(move) || houseRules.contains(move.token) }
    func licenses(_ refusal: Refusal) -> Bool { licensedRefusals.contains(refusal.declaration) }
    mutating func absorb(houseRule: String) { houseRules.insert(houseRule) }
}

/// Iterable by construction. The one thing a World can never do is this struct's `reset()`.
struct GameState {
    private(set) var history: [Move] = []
    mutating func record(_ move: Move) { history.append(move) }
    mutating func reset() { history.removeAll() }
}

// MARK: - Transitional space (Winnicott): the live layer of the circle

/// A spontaneous gesture: not a move, not a refusal.
struct Gesture {
    let by: Person
    let shape: String
}

/// An office is held, not conferred for life: a thing, not a trace. Appointed, resigned, lost.
struct Office: Hashable {
    let name: String
    let rank: Int
    /// The degree one must hold to hold this office.
    let minDegree: Int
    /// nil: unlimited.
    let seats: Int?
    /// The office whose holders may host the circle that fills this one (the conclave).
    let electedBy: String?
}

/// The spoil-sport's act. Not a Move: it is addressed to the players as persons, about the frame
/// itself. When it founds, it is also the constitution of what it founds.
struct Refusal {
    let by: Person
    let declaration: String
    /// The way of being a hero this refusal claims and the circle did not offer (Becker).
    let heroRole: String
    /// Roles of the host world this refusal denies. Non-empty means it can never be chartered.
    var negates: Set<String> = []
    /// Degrees of the world it founds, lowest first. Index is level; the last is the top.
    var degrees: [String] = ["member"]
    var offices: [Office] = []
    /// Authority (office rank) needed to host, charter or suppress inside the world it founds.
    var custodyRank: Int = 0
    /// Graded disclosure: traces are recorded at the degree they concern, not at zero.
    var esoteric: Bool = false
}

/// Faces both ways: a member of the circle who also holds the world.
struct Custodian {
    let person: Person
    let world: World
}

// MARK: - The circle

struct MagicCircle {
    private(set) var rules: Rules
    private(set) var players: Set<Person>
    let custodian: Custodian?
    private(set) var state = GameState()
    private(set) var shattered = false

    init(rules: Rules, players: Set<Person>, custodian: Custodian?) {
        self.rules = rules
        self.players = players
        self.custodian = custodian
    }

    enum PlayOutcome { case played, cheat, outsider, shattered }

    @discardableResult
    mutating func play(_ move: Move) -> PlayOutcome {
        guard !shattered else { return .shattered }
        guard players.contains(move.by) else { return .outsider }
        guard rules.admits(move) else { return .cheat }
        state.record(move)
        return .played
    }

    mutating func reset() { state.reset() }

    enum Reception { case met, unmet, impinged }

    @discardableResult
    mutating func offer(_ gesture: Gesture, takenUpBy others: Set<Person>, challenged: Bool = false) -> Reception {
        guard !shattered, players.contains(gesture.by) else { return .unmet }
        if challenged { return .impinged }
        let uptake = others.subtracting([gesture.by]).intersection(players)
        guard !uptake.isEmpty else { return .unmet }
        rules.absorb(houseRule: gesture.shape)
        return .met
    }

    enum Aftermath {
        case void                           // not a player, or no circle left to refuse
        case sealed                         // no custodian: nowhere to go
        case reincorporated(Conferral?)     // licensed: same circle, same world, maybe a new standing
        case ejected(Person)                // unmet: cast out, the circle re-closes
        case founded(World)                 // met, and held: a new world inside the custodian's
    }

    /// The seam. `withheld` is the custodian defecting: the founding happens, and the parent's
    /// ledger is not told. That is where secret societies come from.
    mutating func rupture(_ refusal: Refusal, followers: Set<Person>, withheld: Bool = false) -> Aftermath {
        guard !shattered, players.contains(refusal.by) else { return .void }
        guard let custodian else { return .sealed }

        if rules.licenses(refusal) {
            var conferred: Conferral? = nil
            if let rite = rules.rites[refusal.declaration] {
                let done: Bool
                switch rite {
                case .degree(let level):
                    done = custodian.world.ordain(refusal.by, to: level, by: custodian.person, before: players)
                case .office(let name):
                    done = custodian.world.install(refusal.by, in: name, before: players)
                }
                if done { conferred = rite }
            }
            return .reincorporated(conferred)
        }

        let band = followers.subtracting([refusal.by]).intersection(players)
        guard !band.isEmpty else {
            players.remove(refusal.by)
            custodian.world.remember(.refusal(refusal.declaration), by: refusal.by, before: players)
            return .ejected(refusal.by)
        }

        shattered = true
        players.subtract(band.union([refusal.by]))
        let new = World(founded: refusal.declaration, by: refusal.by, with: band, remembering: rules.name,
                        heroRoles: [refusal.heroRole], negates: refusal.negates,
                        degrees: refusal.degrees, offices: refusal.offices,
                        custodyRank: refusal.custodyRank, esoteric: refusal.esoteric,
                        parent: custodian.world, secret: withheld)
        if !withheld {
            custodian.world.remember(.founding(new.walls.founding), by: refusal.by,
                                     before: band.union([custodian.person]))
        }
        return .founded(new)
    }

    var isPuerile: Bool { !state.history.isEmpty && rules.houseRules.isEmpty }
}

// MARK: - The world (Arendt)

enum Worldlessness: Error {
    case dispersed
    case unwitnessed
}

/// What a deed leaves. Append-only wherever it is kept. `visibility` is the degree one must hold
/// in this world to read it; zero is public.
struct Trace: Identifiable {
    enum Kind {
        case founding(String)
        case deed(String)
        case word(String)
        case refusal(String)
        case promise(String)
        case forgiveness(of: UUID)
        case charter(String)
        case suppression(String)
        case secession(String)
        case exposure(String)
        case ordination(of: Person, level: Int)
        case appointment(String, of: Person)
        case vacancy(String, of: Person)
        case coinage(String)
        case disclosure(String, to: Person)
        case leak(String, to: Person)
    }
    let id = UUID()
    let by: Person
    let before: Set<Person>
    let kind: Kind
    let visibility: Int
}

/// A deed cannot be copied: there is no second one to try again with. `act` consumes it.
struct Deed: ~Copyable {
    let by: Person
    let what: String
}

/// Durable, destructible, exchangeable. The objective in-between.
struct Thing: Equatable {
    let name: String
}

/// Esoteric content. Note what is not here: a meaning. Its value is its distribution, and
/// `World.currency` computes it from nothing else. That is the hyperreal: a sign whose referent
/// is the set of those who hold it. Unlike a degree it can be burned and recoined.
struct Symbol {
    let sign: String
    let visibility: Int
    fileprivate(set) var holders: Set<Person>
    fileprivate(set) var burned = false

    init(sign: String, visibility: Int, holders: Set<Person>) {
        self.sign = sign
        self.visibility = visibility
        self.holders = holders
    }
}

final class World {
    struct Laws {
        let founding: String
        let remembered: String?
    }

    /// Standing toward the parent. `secret`: founded inside it, absent from its ledger.
    enum Standing { case sovereign, lodged, chartered, suppressed, seceded, secret }

    let walls: Laws
    let founder: Person
    private(set) weak var parent: World?
    /// What the parent knows it contains. A secret child is not here.
    private(set) var children: [World] = []
    private(set) var standing: Standing
    private(set) var heroRoles: Set<String>
    let negates: Set<String>

    // Rank.
    /// Names of the degrees, lowest first. A degree is read off the ledger and never lost.
    let degrees: [String]
    let offices: [String: Office]
    private(set) var incumbents: [String: Set<Person>] = [:]
    let custodyRank: Int
    let esoteric: Bool

    private(set) var members: Set<Person>
    private(set) var things: [Thing] = []
    private(set) var symbols: [String: Symbol] = [:]
    /// Private now. Read it through `ledger(for:)`, which is what disclosure means.
    private var ledger: [Trace] = []

    init(founded declaration: String, by founder: Person, with followers: Set<Person>, remembering old: String?,
         heroRoles: Set<String>, negates: Set<String> = [], degrees: [String] = ["member"],
         offices: [Office] = [], custodyRank: Int = 0, esoteric: Bool = false,
         parent: World? = nil, secret: Bool = false) {
        let others = followers.subtracting([founder])
        precondition(!others.isEmpty, "plurality: a founding needs someone other than the founder")
        precondition(!degrees.isEmpty, "a world has at least one degree")
        walls = Laws(founding: declaration, remembered: old)
        self.founder = founder
        self.parent = parent
        standing = parent == nil ? .sovereign : (secret ? .secret : .lodged)
        self.heroRoles = heroRoles
        self.negates = negates
        self.degrees = degrees
        self.offices = Dictionary(uniqueKeysWithValues: offices.map { ($0.name, $0) })
        self.custodyRank = custodyRank
        self.esoteric = esoteric
        members = others.union([founder])

        // The founding is public even in an esoteric world. (An onion, in Arendt's sense, is a
        // world whose founding trace is itself esoteric: the center's story is for the center.)
        remember(.founding(declaration), by: founder, before: others)
        // The founder holds the top degree and the top office by founding. Everything after is
        // augmentation of this.
        remember(.ordination(of: founder, level: degrees.count - 1), by: founder, before: others)
        if let top = offices.max(by: { $0.rank < $1.rank }) {
            incumbents[top.name] = [founder]
            remember(.appointment(top.name, of: founder), by: founder, before: others)
        }
        if !secret { parent?.children.append(self) }
    }

    // MARK: Memory and disclosure

    @discardableResult
    fileprivate func remember(_ kind: Trace.Kind, by person: Person, before witnesses: Set<Person>,
                              visibility: Int = 0) -> Trace {
        let trace = Trace(by: person, before: witnesses, kind: kind, visibility: visibility)
        ledger.append(trace)
        return trace
    }

    /// What a given viewer can read. A member reads up to their degree; an outsider reads the
    /// public traces of an open world and nothing of a secret one.
    func ledger(for viewer: Person?) -> [Trace] {
        if let viewer, let level = degree(of: viewer) {
            return ledger.filter { $0.visibility <= level }
        }
        return standing == .secret ? [] : ledger.filter { $0.visibility == 0 }
    }

    /// The "who", as a given viewer can see it. Never stored on the person.
    func who(_ person: Person, seenBy viewer: Person?) -> [Trace] {
        ledger(for: viewer).filter { $0.by == person && !$0.before.isEmpty }
    }

    // MARK: Rank

    /// Highest degree conferred in this world. nil for a non-member. Indelible: the ledger only grows.
    func degree(of person: Person) -> Int? {
        guard members.contains(person) else { return nil }
        return ledger.reduce(0) { level, trace in
            if case .ordination(let who, let conferred) = trace.kind, who == person { return max(level, conferred) }
            return level
        }
    }

    /// Highest rank of any office held. Zero for the laity and for outsiders.
    func authority(of person: Person) -> Int {
        offices.values.filter { incumbents[$0.name, default: []].contains(person) }.map(\.rank).max() ?? 0
    }

    /// Confer a degree. The ordainer must hold it. Recorded at that degree if the world is esoteric.
    @discardableResult
    func ordain(_ person: Person, to level: Int, by actor: Person, before witnesses: Set<Person>) -> Bool {
        guard members.contains(person), level < degrees.count, (degree(of: actor) ?? -1) >= level else { return false }
        let others = witnesses.intersection(members).subtracting([person])
        guard !others.isEmpty else { return false }
        remember(.ordination(of: person, level: level), by: actor, before: others, visibility: esoteric ? level : 0)
        return true
    }

    /// Seat someone in an office. No authority check here: the rite is the authority, and `host`
    /// decides who may run the rite.
    @discardableResult
    fileprivate func install(_ person: Person, in name: String, before witnesses: Set<Person>) -> Bool {
        guard let office = offices[name], (degree(of: person) ?? -1) >= office.minDegree else { return false }
        if let seats = office.seats, incumbents[name, default: []].count >= seats { return false }
        incumbents[name, default: []].insert(person)
        remember(.appointment(name, of: person), by: person, before: witnesses.subtracting([person]))
        return true
    }

    /// Appointment from above. Elected offices cannot be filled this way.
    @discardableResult
    func appoint(_ person: Person, to name: String, by actor: Person) -> Bool {
        guard let office = offices[name], office.electedBy == nil, authority(of: actor) > office.rank else { return false }
        return install(person, in: name, before: members)
    }

    /// Resignation, or removal from above. The office is a thing; the degree stays.
    @discardableResult
    func vacate(_ name: String, of person: Person, by actor: Person) -> Bool {
        guard let office = offices[name], incumbents[name, default: []].contains(person),
              actor == person || authority(of: actor) > office.rank else { return false }
        incumbents[name]?.remove(person)
        remember(.vacancy(name, of: person), by: actor, before: members.subtracting([actor]))
        return true
    }

    // MARK: Signs

    @discardableResult
    func coin(_ sign: String, visibility: Int, by actor: Person) -> Bool {
        guard symbols[sign] == nil, (degree(of: actor) ?? -1) >= visibility else { return false }
        symbols[sign] = Symbol(sign: sign, visibility: visibility, holders: [actor])
        remember(.coinage(sign), by: actor, before: [], visibility: visibility)
        return true
    }

    /// Disclosure to someone of sufficient degree. Below it, the method refuses; see `leak`.
    @discardableResult
    func disclose(_ sign: String, to person: Person, by actor: Person) -> Bool {
        guard var symbol = symbols[sign], !symbol.burned, symbol.holders.contains(actor),
              (degree(of: person) ?? -1) >= symbol.visibility else { return false }
        symbol.holders.insert(person)
        symbols[sign] = symbol
        remember(.disclosure(sign, to: person), by: actor, before: symbol.holders.subtracting([actor]),
                 visibility: symbol.visibility)
        return true
    }

    /// Disclosure below degree, or to an outsider. The sign is burned and counts for nothing;
    /// the leaker's degree is untouched. Content is resettable, standing is not.
    @discardableResult
    func leak(_ sign: String, to person: Person, by actor: Person) -> Bool {
        guard var symbol = symbols[sign], symbol.holders.contains(actor) else { return false }
        symbol.holders.insert(person)
        symbol.burned = true
        symbols[sign] = symbol
        remember(.leak(sign, to: person), by: actor, before: symbol.holders.subtracting([actor]))
        return true
    }

    /// Inner social currency: each live sign held, weighted by its scarcity. Distinction is rarity.
    func currency(of person: Person) -> Double {
        symbols.values
            .filter { !$0.burned && $0.holders.contains(person) }
            .reduce(0) { $0 + 1 / Double($1.holders.count) }
    }

    // MARK: Work

    func make(_ thing: Thing) { things.append(thing) }
    func unmake(_ thing: Thing) { things.removeAll { $0 == thing } }

    // MARK: Lodging

    /// Recognition. Widens this world's hero-system by the role the subworld brought. Refused when
    /// the subworld denies a role this world's heroes are made of, or the actor lacks custody.
    @discardableResult
    func charter(_ child: World, by actor: Person) -> Bool {
        guard child.parent === self, child.standing == .lodged,
              members.contains(actor), authority(of: actor) >= custodyRank else { return false }
        guard child.negates.isDisjoint(with: heroRoles) else { return false }
        child.standing = .chartered
        heroRoles.formUnion(child.heroRoles)
        remember(.charter(child.walls.founding), by: actor, before: child.members)
        return true
    }

    /// The other answer to a lodged world. Its members lose this one.
    @discardableResult
    func suppress(_ child: World, by actor: Person) -> Bool {
        guard child.parent === self, child.standing == .lodged,
              members.contains(actor), authority(of: actor) >= custodyRank else { return false }
        child.standing = .suppressed
        members.subtract(child.members)
        remember(.suppression(child.walls.founding), by: actor, before: members)
        return true
    }

    /// The band's answer: keep the walls, leave the parent's.
    func secede() {
        guard let parent, standing == .lodged || standing == .chartered else { return }
        standing = .seceded
        parent.members.subtract(members)
        parent.remember(.secession(walls.founding), by: founder, before: parent.members)
    }

    /// The front collapses (Goffman). A member tells the parent; existence becomes a fact there,
    /// and the parent can now charter or suppress. What was disclosed inside stays inside.
    @discardableResult
    func expose(by whistleblower: Person) -> Bool {
        guard standing == .secret, let parent, members.contains(whistleblower) else { return false }
        standing = .lodged
        parent.children.append(self)
        parent.remember(.exposure(walls.founding), by: whistleblower, before: parent.members)
        return true
    }

    // MARK: Appearance

    func appear<T>(among participants: Set<Person>, _ body: (SpaceOfAppearance) throws -> T) rethrows -> T {
        let space = SpaceOfAppearance(world: self, participants: participants.intersection(members))
        defer { space.close() }
        return try body(space)
    }

    /// A world hosts a circle inside its walls. The custodian needs custody here, and if the
    /// circle's rites fill an office, the right to run that election.
    func host(rules: Rules, players: Set<Person>, custodian person: Person) -> MagicCircle {
        precondition(members.contains(person), "the custodian must belong to the world the circle sits in")
        precondition(authority(of: person) >= custodyRank, "no custody here")
        for rite in rules.rites.values {
            if case .office(let name) = rite, let office = offices[name] {
                let electors = office.electedBy.map { incumbents[$0, default: []] } ?? []
                precondition(authority(of: person) > office.rank || electors.contains(person),
                             "only \(office.electedBy ?? "a superior") may host the circle that fills \(name)")
            }
        }
        return MagicCircle(rules: rules, players: players, custodian: Custodian(person: person, world: self))
    }

    var isSocial: Bool {
        !things.isEmpty && ledger.allSatisfy { trace in
            if case .founding = trace.kind { return true }
            return false
        }
    }
}

final class SpaceOfAppearance {
    let participants: Set<Person>
    private(set) var isOpen = true
    private unowned let world: World

    fileprivate init(world: World, participants: Set<Person>) {
        self.world = world
        self.participants = participants
    }

    fileprivate func close() { isOpen = false }

    @discardableResult
    func act(_ deed: consuming Deed) throws -> Trace {
        guard isOpen else { throw Worldlessness.dispersed }
        let witnesses = participants.subtracting([deed.by])
        guard participants.contains(deed.by), !witnesses.isEmpty else { throw Worldlessness.unwitnessed }
        return world.remember(.deed(deed.what), by: deed.by, before: witnesses)
    }

    @discardableResult
    func forgive(_ trace: Trace, by person: Person) throws -> Trace {
        guard isOpen else { throw Worldlessness.dispersed }
        return world.remember(.forgiveness(of: trace.id), by: person, before: participants.subtracting([person]))
    }

    @discardableResult
    func promise(_ text: String, by person: Person) throws -> Trace {
        guard isOpen else { throw Worldlessness.dispersed }
        return world.remember(.promise(text), by: person, before: participants.subtracting([person]))
    }
}

// MARK: - Scenario: a pyramid, a conclave, an order, and a lodge that cuts across all of it

func hierarchy() {
    let marshal = Person("Marshal")
    let peter = Person("Peter"), john = Person("John"), gregory = Person("Gregory"), ambrose = Person("Ambrose")
    let francis = Person("Francis"), clare = Person("Clare"), licio = Person("Licio"), umberto = Person("Umberto")
    let everyone: Set<Person> = [peter, john, gregory, ambrose, francis, clare, licio, umberto]

    let nation = World(founded: "one people", by: marshal, with: everyone, remembering: "Troy",
                       heroRoles: ["soldier", "founder"])

    // 1. The pyramid. A world chartered in the nation whose constitution is degrees and offices.
    var council = nation.host(rules: Rules(name: "council") { _ in true }, players: everyone, custodian: marshal)
    guard case .founded(let church) = council.rupture(
        Refusal(by: peter, declaration: "on this rock", heroRole: "saint",
                degrees: ["lay", "deacon", "priest", "bishop"],
                offices: [Office(name: "pope", rank: 3, minDegree: 3, seats: 1, electedBy: "cardinal"),
                          Office(name: "cardinal", rank: 2, minDegree: 3, seats: nil, electedBy: nil),
                          Office(name: "bishop", rank: 2, minDegree: 3, seats: nil, electedBy: nil),
                          Office(name: "priest", rank: 1, minDegree: 2, seats: nil, electedBy: nil)],
                custodyRank: 1),
        followers: [john, gregory, ambrose, francis, clare]
    ) else { return }
    nation.charter(church, by: marshal)

    for bishop in [john, gregory, ambrose] { church.ordain(bishop, to: 3, by: peter, before: church.members) }
    church.ordain(francis, to: 2, by: ambrose, before: church.members)
    church.appoint(john, to: "cardinal", by: peter)
    church.appoint(gregory, to: "cardinal", by: peter)
    church.appoint(ambrose, to: "bishop", by: peter)
    church.appoint(francis, to: "priest", by: ambrose)
    print("Peter:", church.degrees[church.degree(of: peter)!], "authority", church.authority(of: peter),
          "| Clare:", church.degrees[church.degree(of: clare)!], "authority", church.authority(of: clare))

    // 2. The apex is filled by a circle. Peter resigns; the cardinals lock themselves in.
    church.vacate("pope", of: peter, by: peter)
    var conclave = church.host(
        rules: Rules(name: "conclave", rites: ["accepto": .office("pope")]) { $0.token == "scrutiny" },
        players: [john, gregory], custodian: john)
    conclave.play(Move(by: john, token: "scrutiny"))
    conclave.play(Move(by: gregory, token: "scrutiny"))
    let habemus = conclave.rupture(Refusal(by: gregory, declaration: "accepto", heroRole: "pope"), followers: [])
    if case .reincorporated(.some(.office(let name))) = habemus {
        print("conclave conferred:", name, "| Gregory's authority now", church.authority(of: gregory),
              "| Peter's", church.authority(of: peter), "degree still", church.degrees[church.degree(of: peter)!])
    }

    // 3. A world inside the pyramid with its own degrees. A friar's rank says nothing about his orders.
    var chapter = church.host(rules: Rules(name: "chapter") { _ in true }, players: [ambrose, francis, clare], custodian: ambrose)
    guard case .founded(let order) = chapter.rupture(
        Refusal(by: francis, declaration: "own nothing", heroRole: "mendicant", degrees: ["novice", "friar"]),
        followers: [clare]
    ) else { return }
    church.charter(order, by: gregory)
    print("Clare in the church:", church.degrees[church.degree(of: clare)!],
          "| in the order:", order.degrees[order.degree(of: clare)!],
          "| Francis in the order:", order.degrees[order.degree(of: francis)!])

    // 4. The lodge. Founded at a dinner the nation hosted; the custodian withholds it.
    var dinner = nation.host(rules: Rules(name: "dinner") { _ in true }, players: [licio, umberto, ambrose], custodian: umberto)
    guard case .founded(let lodge) = dinner.rupture(
        Refusal(by: licio, declaration: "the profane shall not know us", heroRole: "master",
                degrees: ["apprentice", "fellow", "master"],
                offices: [Office(name: "worshipful master", rank: 1, minDegree: 2, seats: 1, electedBy: nil)],
                custodyRank: 1, esoteric: true),
        followers: [umberto, ambrose], withheld: true
    ) else { return }
    print("lodge:", lodge.standing, "| nation knows of", nation.children.count, "child",
          "| nation ledger mentions it:", nation.ledger(for: marshal).contains {
              if case .founding(let f) = $0.kind { return f == lodge.walls.founding }
              return false
          })

    // Initiation is a licensed rupture that writes an indelible trace at the degree it concerns.
    var rite = lodge.host(
        rules: Rules(name: "rite", rites: ["I die to the profane": .degree(1)]) { _ in true },
        players: [licio, umberto, ambrose], custodian: licio)
    _ = rite.rupture(Refusal(by: ambrose, declaration: "I die to the profane", heroRole: "fellow"), followers: [])
    _ = rite.rupture(Refusal(by: umberto, declaration: "I die to the profane", heroRole: "fellow"), followers: [])
    lodge.ordain(umberto, to: 2, by: licio, before: [licio, umberto])

    // Signs: no meaning, only distribution. Disclosure is gated by degree; leaks burn the sign.
    lodge.coin("the grip", visibility: 1, by: licio)
    lodge.coin("the lost word", visibility: 2, by: licio)
    lodge.disclose("the grip", to: ambrose, by: licio)
    lodge.disclose("the grip", to: umberto, by: licio)
    lodge.disclose("the lost word", to: umberto, by: licio)
    print("the lost word to Ambrose:", lodge.disclose("the lost word", to: ambrose, by: licio))

    // 5. Cross-cutting. In the church Ambrose outranks Umberto; in the lodge the reverse.
    print("church authority — Ambrose:", church.authority(of: ambrose), "Umberto:", church.authority(of: umberto))
    print("lodge currency  — Ambrose:", lodge.currency(of: ambrose), "Umberto:", lodge.currency(of: umberto))
    print("lodge ledger as seen by Ambrose:", lodge.ledger(for: ambrose).count,
          "| by Licio:", lodge.ledger(for: licio).count, "| by the Marshal:", lodge.ledger(for: marshal).count)

    // Content resets; standing does not.
    lodge.leak("the lost word", to: marshal, by: umberto)
    lodge.coin("the new word", visibility: 2, by: licio)
    print("after the leak — Licio's currency:", lodge.currency(of: licio),
          "| Umberto still", lodge.degrees[lodge.degree(of: umberto)!])

    // 6. Exposure. The bishop confesses; the lodge is now a fact in the nation, and is suppressed.
    lodge.expose(by: ambrose)
    nation.suppress(lodge, by: marshal)
    print("lodge:", lodge.standing, "| Ambrose in the nation:", nation.members.contains(ambrose),
          "| still a bishop:", church.authority(of: ambrose))
}

hierarchy()
