/*
 * The AcCoRD Simulator
 * (Actor-based Communication via Reaction-Diffusion)
 *
 * Copyright 2016 Adam Noel. All rights reserved.
 *
 * micro_molecule.h - linked list of individual molecules in same
 *                    microscopic region
 *
 * Modified to support per-nanomachine energy tracking.
 *
 * Key change: ItemMol3D and ItemMolRecent3D now carry two extra fields:
 *   - ownerActorID  (short)    : index into actorCommonArray of the
 *                                energy-enabled actor that emitted this
 *                                molecule; -1 if no owner.
 *   - ownerUnitID   (uint32_t) : per-unit index within that actor
 *                                (corresponds to energyCurrentPerUnit[]).
 *
 * These fields are propagated through reactions so that energy costs are
 * always charged to the correct individual nanosensor.
 */

#ifndef MICRO_MOLECULE_H
#define MICRO_MOLECULE_H

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <limits.h>
#include <stdint.h>

#include "region.h"
#include "subvolume.h"
#include "meso.h"
#include "global_param.h"

/* Forward declaration */
struct actorStruct3D;
struct chem_rxn_struct;

/*
 * -----------------------------------------------------------------------
 * Data type declarations
 * -----------------------------------------------------------------------
 */

/*
 * BmIDSet – compact set of biomarker IDs carried by one molecule.
 *
 * n    : number of valid entries in id[] (0 = molecule carries no BM info)
 * id[] : unique biomarker identities assigned at BM placement
 *
 * Two molecules may react only when their BmIDSets have NO overlap.
 * Products inherit the union of both reactants' sets.
 */
#define BM_ID_MAX_TRACK 64

typedef struct {
    uint8_t  n;
    uint64_t id[BM_ID_MAX_TRACK];
} BmIDSet;

/*
 * ItemMol3D – one molecule in the regular (non-recent) microscopic list.
 *
 * ownerActorID == -1  →  molecule has no energy-enabled owner (e.g. it is
 *                         a biomarker, or a reaction product whose owner
 *                         lineage was not tracked).
 * ownerActorID >= 0   →  index into actorCommonArray; the molecule was
 *                         emitted by that actor and its energy costs must
 *                         be charged to ownerUnitID of that actor.
 * bmIDs              →  set of biomarker IDs whose information this
 *                         molecule carries (empty set = no BM info).
 */
typedef struct {
    double   x;
    double   y;
    double   z;
    bool     bNeedUpdate;   /* false once molecule has reacted this step  */
    short    ownerActorID;  /* actor that emitted this molecule (-1: none) */
    uint32_t ownerUnitID;   /* energy unit within that actor               */
    BmIDSet  bmIDs;         /* set of biomarker IDs carried by this molecule */
} ItemMol3D;

typedef struct node_Mol3D {
    ItemMol3D        item;
    struct node_Mol3D * next;
} NodeMol3D;

typedef NodeMol3D * ListMol3D;

/*
 * ItemMolRecent3D – molecule created during the current micro time step.
 * Same owner and bmIDs fields as ItemMol3D.
 */
typedef struct {
    double   x;
    double   y;
    double   z;
    double   dt_partial;    /* how far into the current dt this mol was born */
    short    ownerActorID;
    uint32_t ownerUnitID;
    BmIDSet  bmIDs;         /* set of biomarker IDs carried by this molecule */
} ItemMolRecent3D;

typedef struct node_MolRecent3D {
    ItemMolRecent3D        item;
    struct node_MolRecent3D * next;
} NodeMolRecent3D;

typedef NodeMolRecent3D * ListMolRecent3D;

/*
 * -----------------------------------------------------------------------
 * Function declarations
 * -----------------------------------------------------------------------
 */

/* BmIDSet helpers */
uint64_t assignNewBMID(void);
BmIDSet  bmIDSetEmpty(void);
BmIDSet  bmIDSetFromID(uint64_t id);
bool     bmIDSetOverlap(const BmIDSet *a, const BmIDSet *b);
bool     bmIDSetEqual(const BmIDSet *a, const BmIDSet *b);
bool     bmIDSetIsSubset(const BmIDSet *a, const BmIDSet *b); /* a ⊆ b ? */
BmIDSet  bmIDSetUnion(const BmIDSet *a, const BmIDSet *b);

/* Communication direction from the logged unit's molecule perspective.
 * 0=send  1=receive  2=send & receive */
#define COMM_DIR_SEND    0
#define COMM_DIR_RECEIVE 1
#define COMM_DIR_BOTH    2

/* Basic molecule operations */
bool addMolecule(ListMol3D * p_list, double x, double y, double z);
bool addMoleculeOwned(ListMol3D * p_list, double x, double y, double z,
    short ownerActorID, uint32_t ownerUnitID, BmIDSet bmIDs);
bool addMoleculeOwnedInherited(ListMol3D * p_list, double x, double y, double z,
    short ownerActorID, uint32_t ownerUnitID, BmIDSet bmIDs);

bool addMoleculeRecent(ListMolRecent3D * p_list, double x, double y, double z,
    double dt_partial);
bool addMoleculeRecentOwned(ListMolRecent3D * p_list, double x, double y, double z,
    double dt_partial, short ownerActorID, uint32_t ownerUnitID, BmIDSet bmIDs);

void moveMolecule(ItemMol3D * molecule, double x, double y, double z);
void moveMoleculeRecent(ItemMolRecent3D * molecule, double x, double y, double z);

/* Diffusion and transport */
void diffuseMolecules(const short NUM_REGIONS,
    const unsigned short NUM_MOL_TYPES,
    ListMol3D p_list[NUM_REGIONS][NUM_MOL_TYPES],
    ListMolRecent3D p_listRecent[NUM_REGIONS][NUM_MOL_TYPES],
    const struct region regionArray[],
    struct mesoSubvolume3D mesoSubArray[],
    double sigma[NUM_REGIONS][NUM_MOL_TYPES],
    const struct chem_rxn_struct * chem_rxn,
    const double HYBRID_DIST_MAX,
    double DIFF_COEF[NUM_REGIONS][NUM_MOL_TYPES]);

void diffuseOneMolecule(ItemMol3D * molecule, double sigma);
void flowTransportOneMolecule(ItemMol3D * molecule,
    const unsigned short flowType,
    double * flowConstant);
void diffuseOneMoleculeRecent(ItemMolRecent3D * molecule, double DIFF_COEF);
void flowTransportOneMoleculeRecent(ItemMolRecent3D * molecule,
    const unsigned short flowType,
    double * flowVector);

bool bEnterMesoIndirect(const short NUM_REGIONS,
    const unsigned short NUM_MOL_TYPES,
    const struct region regionArray[],
    const short curType,
    const short curRegion,
    short * mesoRegion,
    const double oldPoint[3],
    const double newPoint[3],
    uint32_t * newSub,
    const double HYBRID_DIST_MAX,
    const double tLeft,
    double DIFF_COEF[NUM_REGIONS][NUM_MOL_TYPES]);

bool placeInMicroFromMeso(const unsigned short curRegion,
    const short NUM_REGIONS,
    const unsigned short NUM_MOL_TYPES,
    const unsigned short destRegion,
    uint32_t * newSub,
    const struct region regionArray[],
    const uint32_t curBoundSub,
    const bool bSmallSub,
    const unsigned short curMolType,
    ListMolRecent3D pRecentList[NUM_REGIONS][NUM_MOL_TYPES],
    const struct chem_rxn_struct * chem_rxn,
    double DIFF_COEF[NUM_REGIONS][NUM_MOL_TYPES]);

/* Chemical reactions */
void rxnFirstOrder(const unsigned short NUM_REGIONS,
    const unsigned short NUM_MOL_TYPES,
    unsigned short curRegion,
    ListMol3D p_list[NUM_REGIONS][NUM_MOL_TYPES],
    const struct region regionArray[],
    unsigned short curMolType,
    double DIFF_COEF[NUM_REGIONS][NUM_MOL_TYPES],
    ListMolRecent3D pRecentList[NUM_REGIONS][NUM_MOL_TYPES],
    struct actorStruct3D * actorCommonArray,
    const short NUM_ACTORS,
    double tCur,
    const struct chem_rxn_struct * chem_rxn);

void rxnFirstOrderRecent(const unsigned short NUM_REGIONS,
    const unsigned short NUM_MOL_TYPES,
    unsigned short curRegion,
    ListMolRecent3D pRecentList[NUM_REGIONS][NUM_MOL_TYPES],
    ListMol3D p_list[NUM_REGIONS][NUM_MOL_TYPES],
    const struct region regionArray[],
    unsigned short curMolType,
    double DIFF_COEF[NUM_REGIONS][NUM_MOL_TYPES],
    bool bCheckCount,
    uint32_t numMolCheck[NUM_REGIONS][NUM_MOL_TYPES],
    struct actorStruct3D * actorCommonArray,
    const short NUM_ACTORS,
    double tCur,
    const struct chem_rxn_struct * chem_rxn);

void rxnFirstOrderProductPlacement(const NodeMol3D * curMol,
    const NodeMolRecent3D * curMolRecent,
    const unsigned short curRxn,
    const unsigned short NUM_REGIONS,
    const unsigned short NUM_MOL_TYPES,
    const unsigned short curRegion,
    ListMol3D p_list[NUM_REGIONS][NUM_MOL_TYPES],
    ListMolRecent3D pRecentList[NUM_REGIONS][NUM_MOL_TYPES],
    const struct region regionArray[],
    const unsigned short curMolType,
    double DIFF_COEF[NUM_REGIONS][NUM_MOL_TYPES],
    bool bRecent,
    bool * bProductIsReactant,
    short ownerActorID,
    uint32_t ownerUnitID,
    BmIDSet bmIDs);

void rxnSecondOrder(const unsigned short NUM_REGIONS,
    const unsigned short NUM_MOL_TYPES,
    ListMol3D p_list[NUM_REGIONS][NUM_MOL_TYPES],
    const struct region regionArray[],
    struct mesoSubvolume3D mesoSubArray[],
    const struct chem_rxn_struct * chem_rxn,
    double DIFF_COEF[NUM_REGIONS][NUM_MOL_TYPES],
    struct actorStruct3D * actorCommonArray,
    const short NUM_ACTORS,
    double tCur);

/* Molecule queries and transfers */
bool moleculeSeparation(ItemMol3D * molecule1, ItemMol3D * molecule2,
    double threshSq);
void transferMolecules(ListMolRecent3D * molListRecent, ListMol3D * molList);
bool validateMolecule(double newPoint[3],
    double oldPoint[3],
    const short NUM_REGIONS,
    const unsigned short NUM_MOL_TYPES,
    const short curRegion,
    short * newRegion,
    short * transRegion,
    bool * bPointChange,
    const struct region regionArray[],
    unsigned short molType,
    bool * bReaction,
    bool * bApmcRevert,
    bool bRecent,
    double dt,
    const struct chem_rxn_struct * chem_rxn,
    double DIFF_COEF[NUM_REGIONS][NUM_MOL_TYPES],
    unsigned short * curRxn);

bool followMolecule(const double startPoint[3],
    double endPoint[3],
    double lineVector[3],
    double lineLength,
    const short startRegion,
    short * endRegion,
    short * transRegion,
    bool * bPointChange,
    const short NUM_REGIONS,
    const unsigned short NUM_MOL_TYPES,
    const struct region regionArray[],
    unsigned short molType,
    bool * bReaction,
    unsigned short * curRxn,
    bool * bApmcRevert,
    bool bRecent,
    double dt,
    const struct chem_rxn_struct * chem_rxn,
    double DIFF_COEF[NUM_REGIONS][NUM_MOL_TYPES],
    unsigned int depth);

unsigned short findDestRegion(const double point[3],
    const unsigned short curRegion,
    const struct region regionArray[]);

uint64_t countMolecules(ListMol3D * p_list, int obsType, double boundary[]);
uint64_t countMoleculesRecent(ListMolRecent3D * p_list, int obsType,
    double boundary[]);
uint64_t recordMolecules(ListMol3D * p_list, ListMol3D * recordList,
    int obsType, double boundary[], bool bRecordPos, bool bAllInside);
uint64_t recordMoleculesRecent(ListMolRecent3D * p_list, ListMol3D * recordList,
    int obsType, double boundary[], bool bRecordPos, bool bAllInside);
bool isMoleculeObserved(ItemMol3D * molecule, int obsType, double boundary[]);
bool isMoleculeObservedRecent(ItemMolRecent3D * molecule, int obsType,
    double boundary[]);

/* List management */
void initializeListMol(ListMol3D * p_list);
void initializeListMolRecent(ListMolRecent3D * p_list);
bool isListMol3DEmpty(const ListMol3D * p_list);
bool isListMol3DRecentEmpty(const ListMolRecent3D * p_list);
void emptyListMol(ListMol3D * p_list);
void emptyListMol3DRecent(ListMolRecent3D * p_list);

#endif /* MICRO_MOLECULE_H */
