# DCR-MagicCircle

How can we model real-world Secret Societies (and other esoteric hierarchical superorgs) in the DCR?

This is a self-contained, runnable Swift script that encodes a precise model of nested social worlds as types. It treats a magic circle as the temporary play/transitional space in which a world can be founded, ranked, kept secret, or dissolved, and it makes the distinction between indelible standing and revocable office, and between content and distribution, into enforceable structure rather than commentary. 

## The two containers and their layers 
The file is organized around the comment at the top: 
- A **MagicCircle** is play space (Huizinga) plus transitional space (Winnicott).
- A **World** is transactional space (things, walls) plus space of appearance (Arendt). 

**Person** is deliberately thin: only a name. Who a person is, what rank they hold, and what currency they possess are never stored on the person. They are read off a world’s ledger, and they differ from world to world. 

**Play space** is **Rules** + **Move** + **GameState**. Rules admit moves and can absorb house rules that originated as gestures. They also know their own licensed refusals (the fool, the carnival king, “I quit”) and, separately, rites that change standing in the hosting world. **GameState** is iterable by construction; the only thing a World can never dois **reset()**. 

**Transitional space** is **Gesture**. A gesture is not a move and not a refusal. If other players take it up, it is absorbed as a house rule. If it is challenged, it is impinged. This is the Winnicott layer: spontaneous shape that may or may not become durable. 

The seam is **Refusal**. It is addressed to the players as persons, about the frame itself. It carries a hero role the circle did not offer, optional negations of the host world’s hero roles, and (if it is to found) the degrees and offices of the new world. The key method is **MagicCircle.rupture**. Depending on uptake and whether the refusal is licensed: 
- licensed → reincorporated (same circle, same world, possibly a new degree or office) 
- unmet → ejected 
- met and held → a new **World** is founded inside the custodian’s world 

The withheld flag is the custodian defecting: the founding occurs and the parent’s ledger is not told. That is the origin of secret societies in the model. 

## Rank, secrecy, and signs 
Rank lands on the world’s two layers: 
- A **degree** is conferred and indelible. It is a trace (**ordination**). The ledger only grows. Highest degree held is computed by reduction over the ledger. 
- An **office** is held and vacated. It is a thing. It has rank, a minimum degree, optional seat limits, and optional electors. Appointment and vacancy are recorded; the degree remains. 

Secrecy has two distinct forms: 
- **Esoteric**: graded disclosure of content. Traces are recorded at the degree they concern; a viewer’s ledger(for:) filters by the degree they hold. The founding itself remains public even in an esoteric world.
- **Secret**: a founding withheld from the parent’s ledger. The child has standing **.secret**,is absent from the parent’s **children**, and an outsider (or even a parent- 
- world member) sees an empty ledger. Exposure collapses the front: a member can call **expose**, after which the parent knows the child exists and can charter or suppress it. 

A **Symbol** (sign) has no meaning field. Its value is its distribution. **World.currency(of:)** sums the reciprocal of the number of holders of each live (unburned) sign the person holds. Distinction is rarity. Coining, disclosure (to someone of sufficient degree), and leakage are all traces. A leak burns the sign (it now counts for nothing) but does not touch the leaker’s degree. Content is resettable; standing is not. 

## Dynamics between worlds 
Worlds have standing toward a parent: sovereign, lodged, chartered, suppressed, seceded, or secret. A lodged world can be chartered (widening the parent’s hero roles, unless the child negates one of them) or suppressed (its members lose the parent world). Secession keeps the child’s walls and leaves the parent. Custody rank governs who may host circles, charter, or suppress inside a world. Offices that are elected can only be filled by a circle hosted by someone with the right to run that election (the conclave pattern). 

**SpaceOfAppearance** is the temporary site of deeds, promises, and forgiveness. A Deed is non-copyable; act consumes it. Unwitnessed appearance is an error. The ledger remains append-only; forgiveness and promises are further traces. 

## What the scenario demonstrates
**hierarchy()** walks a single parent world (“one people”) through: 
1. Founding and chartering a ranked church (degrees + offices, including an elected pope). 
2. A conclave: Peter resigns the office; the cardinals lock themselves in a circle whose licensed rite installs a new pope. Degree survives the vacancy. 
3. An order inside the church with its own degrees. A person’s rank in one says nothing about the other. 
4. A secret, esoteric lodge founded at a dinner and withheld from the nation’s ledger. Initiation is a licensed rupture that writes an indelible trace at the degree it concerns. Signs are coined, disclosed by degree, and one is leaked (burned). 
5. Cross-cutting membership: Ambrose outranks Umberto in the church; the reverse holds for lodge currency. 
6. Exposure by a member, followed by suppression. The lodge’s standing changes; the church office held by the exposer does not. 

The prints at the end make the invariants visible: degree is indelible and local, office is revocable, secrecy is a relation to a parent ledger, and a sign’s value is only its distribution. 

### Technical character 
The code is careful about what is stored versus computed. Degree and “who” are reductions over filtered ledgers. Parent links are weak; secret children are simply not inserted into **children**. Visibility is a first-class field on traces and symbols. The non-copyable **Deed** and the precondition that a founding requires plurality are structural, not comments. The whole thing is written so that the philosophical distinctions (trace vs. thing, content vs. distribution, licensed rupture vs. founding rupture, esoteric vs. secret) are the type and method boundaries. 
It is a specification of nested worlds in which rank, secrecy, and signs are not added features but consequences of how ledgers, visibility, and runtire are defined.
