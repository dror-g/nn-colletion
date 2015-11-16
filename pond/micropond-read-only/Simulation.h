#ifndef SIMULATION_H_
#define SIMULATION_H_

#include <QtCore>


//#define CLEANROOM

//#define NANOSTYLE

//comment out if you want debug mode  -----start
#ifndef CLEANROOM

	//#define DECREASE_ENERGY //decreases energy over time
	//#define EXECUTION_ERRORS //creates random execution errors

	#define REPRODUCTION_ERRORS //mutates genome when reproducing
	#define DEAD_MUTATION //mutates dead cells

	#define RANDOM_INITIAL_CELLS

	#ifndef NANOSTYLE
		#define DISASTERS
		#define BAD_KILLS
		#define MUST_REPRODUCE //creatures get killed if they don't reproduce
	#endif
#endif
//comment out if you want debug mode -------end

#define WORLD_X 680
#define WORLD_Y 480
#define WORLD_Z 1
#define GENOME_SIZE 100 //number of operations in a genome

#ifndef NANOSTYLE
        #define GENOME_OPERATIONS 40 //number of different operations
	#define NO_REP_OPERATION 11 //id of the NO REPRODUCE operation
#else
	#define GENOME_OPERATIONS 17 //nanopond style
	#define NO_REP_OPERATION 1 //nanopond style
#endif

#define EAT_ENERGY GENOME_SIZE //amount of energy gained from eating

#define LIVING 3 //minimum generation to be considered alive

#define MAX_EXECUTION_ROW 5 //how many cells can be executed in a row

#define DIRECTIONS 4 //change if you want 3d

#define SPEEDUP_CELLS 1000

#define NORTH 0
#define WEST 1
#define SOUTH 2
#define EAST 3
#define UP 4
#define DOWN 5

#define MUTATION_RATE_REPRODUCTION 6000
//#define MUTATION_RATE_EXECUTION 100000
//#define MUTATION_RATE_NON_LIVING 200
//#define MAX_MUTATIONS_NON_LIVING 3

#define ENERGY_ADDED 5000
#define ENERGY2_ADDED 100
#define ENERGY_FREQUENCY 25

#define REPRODUCTION_COST_FACTOR 1

#define ENERGY_DECREASE 5000000

#define ENERGY2_CONVERSION_GAIN 15

#define MIN_COPY 5

#define MAX_ENERGY 6000
#define MAX_ENERGY2 1000

#define DISASTER_CHANCE 8000000

#define SAVE_TIME 300000000 //+- 3 minutes with no disasters

#define LANDSCAPE_LINES 6

#define MAX_EXECUTING 1300

#define SPECIAL_COMMANDS 5 //number of allowed special commands like kill, move

#define MY_PI 3.14159265

#define MY_RAND_MAX 0x7FFFFFFF

enum Disasters
{
	Meteor,
	Poison,
	Hunger,
	Killer,
	Living,
	Flood
};

enum EnergyDistribution{
    Even,
    Centered,
    CornerBlobs,
    Diamonds,
    Energy2Inclusions,
    Energy2Land
};

struct Cell{
	uint genome_size;
	uint genome_operations;
	qlonglong id;
	qlonglong parent;
	uint generation;
	uint energy;
	uint energy2;
	qlonglong lineage;
	uchar genome[GENOME_SIZE+1];
	uchar reproduced;
	uint bad;
	uint brain;
	struct Place *place;
	uint size;
	uchar facing;
	uint homePond;
        qlonglong injected;
};

struct Place{
	bool dead; //can we reproduce at this place?
};

struct Position{
	int x;
	int y;
	int z;
};

class Simulation: public QThread
{
	Q_OBJECT

public:
	Simulation(QQueue <struct Cell>*pool,QSemaphore *geneblocker,int id);
	virtual ~Simulation();
	void run();
        void stopIt(){running = false;}

	int x(){ return WORLD_X;}
	int y(){ return WORLD_Y;}
	int z(){ return WORLD_Z;}

	struct Cell *cell(int x, int y, int z);

	int genomeSize(){ return GENOME_SIZE;}

	void regenerateEnergy();
	void pause();
	void resume();
        uint counter(){return count;}
        void setEnergyAdd(uint value){ energyAdd = value;}
        uint getEnergyAdd(){return energyAdd;}
        uint getMaxEnergyAdd(){ return ENERGY_ADDED;}

	void saveWorld(QString file);
	void loadWorld(QString file);
	int id(){return myId;}
	int executed();
	void init();
	void addCell(uchar *genome, uint size);
	quint32 getLiving(){return totalLiving;}

private:
	struct Cell cells[WORLD_X][WORLD_Y][WORLD_Z];
	struct Place world[WORLD_X][WORLD_Y][WORLD_Z];
	unsigned long long cellid; //used to track new cells
	bool running; //stop exection when false
	QSemaphore *mutex;
	unsigned long long round; //total number of rounds
	uint count; //stat value

	uint energyAdd;

	inline uchar randomOperation();
	inline int randomX();
	inline int randomY();
	inline int randomZ();
	inline int randValue(int value);

	virtual void executeCell1(int x, int y, int z); //nano pond style
	virtual void executeCell2(int x, int y, int z); //custom style

	virtual void mutateCell(struct Cell *cell);
	virtual void killCell(struct Cell *cell);
	virtual bool reproduce(struct Cell *cell, struct Cell *neighbour,uchar *output_buffer);

	virtual bool accessOk(struct Cell *source, struct Cell *dest, char guess,bool good);
	virtual struct Position getNeighbour(int x, int y, int z, uchar direction);
	virtual void disaster();

        inline void initRNG(int number);
        inline quint32 randomNumber();
        inline quint32 bigrand();

	int nextx;
	int nexty;
	int nextz;
	bool nextSet;
	int canExecuteNext;

	unsigned long mutated;
	bool initialized;
	int myId;

	QQueue <struct Cell>*genepool;
	QSemaphore *genepoolblocker;


        static const double randScale  = 1.0 / (1.0 + MY_RAND_MAX);
        static const double randScaleX  = WORLD_X / (1.0 + MY_RAND_MAX);
        static const double randScaleY  = WORLD_Y / (1.0 + MY_RAND_MAX);

	bool catas;
        qint32 totalLiving;

	int genomeOperations;
	int noRepOperation;

        EnergyDistribution energyMode;

        quint32 nextRNG;
        static const double randScaleBig  = 1.0 / (1.0 + MY_RAND_MAX);
};

#endif /*SIMULATION_H_*/
