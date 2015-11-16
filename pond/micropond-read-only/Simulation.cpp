#include "Simulation.h"
#include <cstring>
#include <stdlib.h>


inline quint32 Simulation::bigrand() {
        return randomNumber();
}

inline void Simulation::initRNG(int number){
    nextRNG = number;
}

inline quint32 Simulation::randomNumber(){
    nextRNG =( 1103515245 * nextRNG+12345)&(0x7FFFFFFF);
    return nextRNG;
    //return qrand();
}

Simulation::Simulation(QQueue <struct Cell>*pool,QSemaphore *geneblocker,int id)
{
        /*

        int i = 0;
        int *a = new int[1000];
        for (;i < 1000; i++){
            a[i] = 0;
        }

        for (i = 0;i < 1000000; i++){
            a[randValue(1000)]++;
        }

        int min = a[0];
        int max = a[0];
        for (i = 0;i < 1000; i++){
            max = qMax(max, a[i]);
            min = qMin(min, a[i]);
        }

        qDebug() << min << max;*/
        myId = id;
        initRNG(myId*1234 + time(NULL));

	genepool = pool;
	genepoolblocker = geneblocker;

	cellid = 0;
	mutated = 0;
	running = true;
	mutex = new QSemaphore(0);
	count = 0;
        energyAdd = (ENERGY_ADDED / 3) + randValue(2 * ENERGY_ADDED / 3);
	nextSet = false;
	canExecuteNext = true;
	initialized = false;
	catas = false;
	totalLiving = 0;
	genomeOperations = GENOME_OPERATIONS;
        noRepOperation = NO_REP_OPERATION;

        switch(randValue(6)){
            case 0:
                energyMode = Even;
            break;
            case 1:
                energyMode = Centered;
            break;
            case 2:
                energyMode = CornerBlobs;
            break;
            case 3:
                energyMode = Diamonds;
            break;
            case 4:
                energyMode = Energy2Inclusions;
            break;
            case 5:
                energyMode = Energy2Land;
            break;
        }

        if(myId == 0){
            energyMode = Centered;
        }

        if(myId == 1){
            energyMode = Energy2Inclusions;
        }
}

Simulation::~Simulation()
{
}

void Simulation::pause(){
	mutex->acquire(1);
}

void Simulation::resume(){
	mutex->release(1);
}

int Simulation::executed(){
	uint temp = count;
	count = 0;
	//qDebug() << "mutated " << mutated << "in pond" << myId;
	mutated = 0;
	return temp;
}

/*
 * Main process
 * is a loop executing the main code of the program, till the user
 * sends through the graphical interface a stop command which sets the
 * running variable to false
 */
void Simulation::run(){
	running = true;
	//mutex->acquire(1);

	//qsrand(0);

	if(!initialized){
		init();
	}

	int x,y,z;
	struct Cell *cell;
	struct Place *world;

	round = 0;
	mutex->release(1);

        while(running){
	    //mutex->acquire(1);
		round++;
		count++;
                if(__builtin_expect(nextSet, false)){
			x = nextx;
			y = nexty;
			z = nextz;
			nextSet = false;
			canExecuteNext--;
		}else{
			//Select random cell
			x = randomX();
			y = randomY();
			z = randomZ();
			canExecuteNext = MAX_EXECUTION_ROW;
		}

		cell = &cells[x][y][z];
		world = cell->place;



#ifdef DECREASE_ENERGY
		if(round % ENERGY_DECREASE == 0){
			qDebug() << "Decrease energy";
			energyAdd -= 100;
			if(energyAdd < 0){
				energyAdd = 0;
			}
		}
#endif
		//add energy every x rounds
                if(__builtin_expect(!(round % ENERGY_FREQUENCY),false)){
			regenerateEnergy();

                        //HACKS
                        if(totalLiving < 0){
                            totalLiving = 0;
                        }
                        //qsrand(QDateTime::currentDateTime().toTime_t());
		}

#ifdef DISASTERS
                if(__builtin_expect(round == SAVE_TIME, false)){
                    catas = true;
                }

                if(__builtin_expect(catas && totalLiving < SPEEDUP_CELLS, false)){
                    catas = false;
                    round = 0;
                }

		//disaster :-)
                if(__builtin_expect(randValue(DISASTER_CHANCE) == 0 && catas, false)){
			disaster();
		}
#endif


                if(__builtin_expect((totalLiving > SPEEDUP_CELLS) && cell->generation < LIVING, false)) {
			continue;
		}

#ifdef DEAD_MUTATION
		//if there is one make the cell mutate
		if(!cell->generation && !world->dead){
			mutateCell(cell);
		}
#endif

#ifdef BAD_KILLS
                if(cell->generation >= LIVING && cell->bad > 3){
			double killValue = 90.0 /
				(( cell->bad) * ( cell->bad));

			//qDebug() << "bad" << killValue << cell->bad;
			if(((int) killValue) == 0 || (randValue((int) killValue)) == 0){
				killCell(cell);
			}
			continue;
		}
#endif

		//kills a cell if there is not energy left and it's a child
		if(!cell->energy && cell->generation >= LIVING && randValue(4)){
			killCell(cell);
		}else if(!world->dead){
			//call the execution of its code
#ifdef NANOSTYLE
			Simulation::executeCell1(x,y,z);
#else
			Simulation::executeCell2(x,y,z);
#endif
		}

		//mutex->release(1);
	}
}

void Simulation::killCell(struct Cell *cell){
        if(cell->id && cell->generation >= LIVING)
		totalLiving--;

	cell->parent = 0;
	cell->lineage = 0;
	cell->generation = 0;
	cell->id = 0;
	cell->genome_size = GENOME_SIZE;
	cell->reproduced = 0;
	cell->brain = 0;
	cell->size = 1;
	cell->facing = 0; //randValue(DIRECTIONS);
	cell->homePond = myId;
	cell->genome_operations = genomeOperations;
        cell->injected = 0;

#ifdef RANDOM_INITIAL_CELLS

	int randStuff = GENOME_SIZE / 4;
	for(int i = 0; i < randStuff; i++){
		cell->genome[i] = randomOperation();
	}

	memset(&cell->genome[randStuff],
			genomeOperations - 1,
			(GENOME_SIZE - randStuff) * sizeof(uchar));

	cell->genome[GENOME_SIZE] = 0x00;
#else
	memset(cell->genome,
				genomeOperations - 1,
				GENOME_SIZE * sizeof(uchar));

	cell->genome[GENOME_SIZE] = 0x00;
#endif
}

void Simulation::addCell(uchar *genome, uint size){
	//get random cell, that is not a wall
	int x,y,z;

	do{
            x = randomX();
            y = randomY();
            z = randomZ();
	}while(world[x][y][z].dead);

	//kill the cell
	struct Cell *cell = &cells[x][y][z];
	killCell(cell);

	//put the new genome in it and fill the blanks
	if(size > GENOME_SIZE){
		qDebug() << "error, the genome size is too big";
	}

	memset(cell->genome,
				genomeOperations - 1,
				GENOME_SIZE * sizeof(uchar));

	memcpy(cell->genome, genome, size);
        cell->generation = LIVING;

}

/**
 * regenarates the energy of one cell
 */
void Simulation::regenerateEnergy(){
	double x = randomX();
	double y = randomY();
	double z = randomZ();

	if(world[(int)x][(int)y][(int)z].dead){
		return;
	}

	double mod = 1.0;
        double mod2 = 0.0;

        switch(energyMode){
            case Even:
            break;
            case Centered:
                if(x <= WORLD_X / 2){
                    mod *= x / (WORLD_X / 2.0);
                }else{
                        mod *= 2.0 - (x / (WORLD_X / 2.0) );
                }

                if(y <= WORLD_Y / 2){
                        mod *= y / (WORLD_Y / 2.0);
                }else{
                        mod *= 2.0 - (y / (WORLD_Y / 2.0) );
                }

                mod += 0.1;
            break;
            case CornerBlobs:
                mod = sin((x / (2.*(WORLD_X/3.) ))*2*MY_PI)+cos((y/ (2.*(WORLD_Y/3.) ))*2*MY_PI);
                mod = qMax(0.08, qMin((double)1.0, mod));
            break;
            case Diamonds:
                mod = sin((x / (WORLD_X/7.))*2*MY_PI)+cos((y/ (WORLD_Y/7. ))*2*MY_PI);
                mod = qMax(0.08, qMin((double)1.0, mod));
            break;
            case Energy2Inclusions:
                mod2 = sin((x / (WORLD_X/2.))*2*MY_PI)+cos((y/ (WORLD_Y/2. ))*2*MY_PI);
                mod2 = qMax(0.08, qMin((double)1.0, mod2));
                mod = 1.0 - mod2;
            break;
            case Energy2Land:
                mod2 = sin(((double)x/ (WORLD_X))*2*MY_PI)+cos(((double)y/ (WORLD_Y ))*2*MY_PI+MY_PI);
                mod2 = qMax(0.0,qMin((double)1.0, mod2));
                mod = 1.0 - mod2;
            break;
        }

	struct Cell *cell = &cells[(int)x][(int)y][(int)z];
	if(cell->energy < MAX_ENERGY){
                cell->energy += (int)((double)energyAdd * mod);
	}

        if(cell->energy2 < MAX_ENERGY2){
            cell->energy2 += (int)((double)ENERGY2_ADDED * mod2);
        }

	if(cell->bad > 1 && randValue(2)){
		cell->bad--;
	}else if(randValue(5) == 0){
		cell->bad++;
	}
}


/**
 * return true if a certain type of action is allowed from cell source to
 * cell dest.
 * The action can be specified with the parameter good
 * the chance of success can be better with the guess parameter
 */
bool Simulation::accessOk(struct Cell *source, struct Cell *dest, char guess,bool good){
        if(__builtin_expect(dest->place->dead, false)){
		return false;
	}

	if(dest->generation <= LIVING ||
			dest->genome[0] == guess ||
			(dest->genome[0] == source->genome[0] && good)){
		return true;
	}

	double temp = (double)source->size / dest->size;

        if(temp < 0.4){
		return false;
	}else if(temp > 2){
		return true;
	}

	int access_chance = 10 - (int)(6.0 * temp - 3.0);

        if(__builtin_expect(access_chance == 0, false))
		return true;

	return !(randValue(access_chance));
}

/**
 * Executes this cell
 */
void Simulation::executeCell2(int x, int y, int z){
	struct Cell *cell = &cells[x][y][z]; //current cell
        __builtin_prefetch(cell->genome,0,0);
        uchar inst; //current instruction
        int genome_pointer = 0; //pointer to the current genome instruction
        int output_pointer = 0; //pointer to the outputbuffer
        uchar output_buffer[GENOME_SIZE]; //outputbuffer, needed for reproducing
        bool stop = false;
        bool reproducing = true;
        struct Cell *tmpCell; //temporary cell

        memset(output_buffer, noRepOperation, GENOME_SIZE * sizeof(uchar));

        genome_pointer = 0;
        int pointer = 0;//general pointer
        uchar facing = cell->facing;
        int reg = 0; //internal register to be used for anything
        int temp = 0; //temp register
        uint executed = 0;
        uint specCommands = 0; //only allow a certain amout of kills
        int injected = 0;

        //Execute cell until no more energy is left
        while(cell->energy && !stop && executed < MAX_EXECUTING){
                executed++;
                inst = cell->genome[genome_pointer];
                genome_pointer++;

                if(__builtin_expect(genome_pointer > GENOME_SIZE-1, false)){
                        genome_pointer = 0;
                }
                cell->energy--;

                switch(inst){
                case 0:
                        pointer = 0;
                        reg = 0;
                        temp = 0;
                        break;
                case 1: //pointer ++
                        pointer++;
                        if(__builtin_expect(pointer >= GENOME_SIZE, false) ){
                                pointer = 0;
                        }
                        break;
                case 2: //pointer --
                        pointer--;
                        if(__builtin_expect(pointer < 0, false)){
                                pointer = GENOME_SIZE - 1;
                        }
                        break;
                case 3: //register ++
                        reg++;
                        if(__builtin_expect(reg >= genomeOperations, false) ){
                                reg = 0;
                        }
                        break;
                case 4: //register --
                        reg--;
                        if(__builtin_expect(reg < 0, false) ){
                                reg = genomeOperations - 1;
                        }
                        break;
                case 5: //read genome to register
                        reg = cell->genome[pointer];
                        break;
                case 6: //write register to outputbuffer
                        output_buffer[pointer] = reg;
                        break;
                case 7: //read output buffer to register
                        reg = output_buffer[pointer];
                        break;
                case 8:{ //look into direction specified in the register
                        facing = reg % DIRECTIONS;
                        injected = 0;
                }break;
                case 9://while(register){
                        if(!reg){
                                int tempP = genome_pointer;
                                uchar *comm = &cell->genome[genome_pointer];
                                while(*comm != 10 &&
                                                cell->energy &&
                                                !stop){

                                        genome_pointer++;
                                        comm++;

                                        cell->energy--;

                                        if(genome_pointer == tempP ||
                                           genome_pointer >= GENOME_SIZE){
                                                stop = true;
                                        }
                                }

                                genome_pointer++;
                                if(__builtin_expect(genome_pointer >= GENOME_SIZE, false))
                                        genome_pointer = 0;
                        }
                        break;
                case 10://}
                        if(reg){
                                int tempP = genome_pointer;
                                uchar *comm = &cell->genome[genome_pointer];
                                while(*comm != 9 &&
                                                cell->energy &&
                                                !stop){
                                        genome_pointer--;
                                        comm--;
                                        cell->energy--;

                                        if(genome_pointer == tempP ||
                                                        genome_pointer < 0){
                                                stop = true;
                                        }
                                }

                                genome_pointer++;
                                if(__builtin_expect(genome_pointer >= GENOME_SIZE, false))
                                        genome_pointer = 0;
                        }
                        break;
                case 11://NOP
                        break;
                case 12:{ //move
                        struct Position pos = getNeighbour(x,y,z,facing);
                        tmpCell = &cells[pos.x][pos.y][pos.z];

                        if(tmpCell != cell && accessOk(cell, tmpCell, reg,false) && cell->energy2 >= 3){
                                cell->energy2 -= 3;
                                int tempEnergy = cell->energy2;
                                cell->energy2 = cell->energy2 / 2 + tmpCell->energy2;
                                tmpCell->energy2 = tempEnergy / 2;

                                tempEnergy = cell->energy;
                                cell->energy = cell->energy / 2 + tmpCell->energy;
                                tmpCell->energy = tempEnergy / 2;

                                struct Cell tmp;
                                tmp = *tmpCell;
                                *tmpCell = *cell;
                                *cell = tmp;

                                struct Place *p = tmpCell->place;
                                tmpCell->place = cell->place;
                                cell->place = p;

                                x = pos.x;
                                y = pos.y;
                                z = pos.z;
                                cell = &cells[x][y][z];
                                stop = true;
                                specCommands++;
                                injected = 0;
                        }
                        if(__builtin_expect(specCommands >= SPECIAL_COMMANDS, false)){
                                stop = true;
                        }
                }break;
                case 13:{ // kill
                        struct Position pos = getNeighbour(x,y,z,facing);
                        tmpCell = &cells[pos.x][pos.y][pos.z];
                        if(cell->generation >= LIVING  &&
                                        accessOk(cell, tmpCell, reg,false)){
                                killCell(tmpCell);
                                specCommands++;
                        }
                        if(specCommands >= SPECIAL_COMMANDS){
                                stop = true;
                        }
                }break;
                case 14:{//remove bad
                        if(cell->bad > 2 && cell->energy >= ENERGY2_CONVERSION_GAIN / 4){
                                cell->bad -= 2;
                                cell->energy -= ENERGY2_CONVERSION_GAIN / 4;
                        }
                }break;
                case 15:{//share
                        struct Position pos = getNeighbour(x,y,z,facing);
                        tmpCell = &cells[pos.x][pos.y][pos.z];
                        if(accessOk(cell, tmpCell, reg,true)){
                                uint tmpEnergy = tmpCell->energy + cell->energy;
                                tmpCell->energy = tmpEnergy / 2;
                                cell->energy = tmpEnergy / 2;
                        }
                }break;
                case 16:{//swap temp
                        int t = temp;
                        temp = reg;
                        reg = t;
                    }
                    break;
                case 17://save reg in brain
                        cell->brain = reg;
                        break;
                case 18:{//neigbour type
                        struct Position pos = getNeighbour(x,y,z,facing);
                        tmpCell = &cells[pos.x][pos.y][pos.z];
                        if(world[pos.x][pos.y][pos.z].dead){
                                reg = 0; //0 if the neighbour is a dead cell
                        }else if(!tmpCell->generation){
                                reg = 1; //registry is 1 if neighbour is very young
                        }else if(tmpCell->genome[0] == cell->genome[0]){
                                reg = 2; //2 if same logo, friend
                        }else{
                                reg = 3; //3 if enemy
                        }
                }break;
                case 19:{//execute neigbour
                        if(canExecuteNext && cell->energy2){
                                int executeDir = reg % DIRECTIONS;
                                struct Position pos = getNeighbour(x,y,z,executeDir);
                                nextx = pos.x;
                                nexty = pos.y;
                                nextz = pos.z;
                                nextSet = true;
                                cell->energy2--;
                        }
                        stop = true;
                }break;
                case 20:{//recall brain
                        reg = cell->brain;
                }break;
                case 21: //tmp == reg ?
                        if(temp == reg){
                                reg = 1;
                        }else{
                                reg = 0;
                        }
                        break;
                case 22:{ //seek most energy
                        uint max = 0;
                        for(int i = 0; i < DIRECTIONS; i++){
                                struct Position pos = getNeighbour(x,y,z,i);
                                tmpCell = &cells[pos.x][pos.y][pos.z];
                                if(max < tmpCell->energy){
                                        reg = i;
                                        max = tmpCell->energy;
                                }
                        }
                }
                        break;
                case 23:{//modify neighbour genome
                        struct Position pos = getNeighbour(x,y,z,facing);
                        tmpCell = &cells[pos.x][pos.y][pos.z];
                        if(cell->generation > LIVING && accessOk(cell, tmpCell, reg,false)){

                                tmpCell->genome[pointer] = output_buffer[pointer];
                                if(randValue(1000) == 0){
                                    tmpCell->genome[pointer] = randomOperation();
                                }

                                if(output_buffer[pointer] != GENOME_OPERATIONS - 1){
                                    tmpCell->size += ++injected;
                                }

                                if(tmpCell->size > 100){
                                    tmpCell->size = 100;
                                }

                                if(tmpCell->size > 5){
                                    if(cell->id == 0){
                                        cell->id = ++cellid;
                                        cell->lineage = cell->id;
                                    }

                                    if(tmpCell->generation < LIVING && cell->generation+1 >= LIVING){
                                        totalLiving++;
                                    }

                                    tmpCell->injected = cell->lineage;
                                    tmpCell->generation = cell->generation+1;
                                    tmpCell->id = ++cellid;

                                    if(tmpCell->lineage == 0){
                                        tmpCell->lineage = cell->lineage;
                                    }
                                }
                        }
                }break;
                case 24:{//convert
                        if(cell->energy2){
                            cell->energy2--;
                            cell->energy += ENERGY2_CONVERSION_GAIN;
                            if(__builtin_expect(randValue(30) == 0, false)){
                                    cell->bad++;
                            }
                        }
                }break;
                case 25:{//eject
                        struct Position pos = getNeighbour(x,y,z,facing);
                        tmpCell = &cells[pos.x][pos.y][pos.z];
                        if(accessOk(cell, tmpCell, reg,true)){

                                switch(reg){
                                        case 0:{ //eject bad particle
                                                if(cell->bad){
                                                        cell->bad--;
                                                        tmpCell->bad++;
                                                }
                                        }break;
                                        case 1:{
                                                if(tmpCell->bad){
                                                        cell->bad++;
                                                        tmpCell->bad--;
                                                }
                                        }break;
                                        default:{
                                                if(cell->energy >= (uint)reg){
                                                        cell->energy -= reg;
                                                        tmpCell->energy += reg;
                                                }
                                        }break;
                                }

                                uint tmpEnergy = tmpCell->energy + cell->energy;
                                tmpCell->energy = tmpEnergy / 2;
                                cell->energy = tmpEnergy / 2;
                        }
                }break;
                case 26: //random
                        reg = randomOperation();
                        break;
                case 27: //test output pointer
                        if(output_pointer != GENOME_SIZE - 1){
                                reg = 1;
                        }else{
                                reg = 0;
                        }
                        break;
                case 28: //if
                        if(reg){
                                reg++;
                                if(reg >= genomeOperations ){
                                        reg = 0;
                                }
                        }
                        break;
                case 29: //if not
                        if(!reg){
                                reg++;
                                if(reg >= genomeOperations ){
                                        reg = 0;
                                }
                        }
                        break;
                case 30: //number of directions
                        reg = DIRECTIONS - 1;
                        break;
                case 31:{ //see neighbour facing
                        struct Position pos = getNeighbour(x,y,z,facing);
                        tmpCell = &cells[pos.x][pos.y][pos.z];
                        reg = tmpCell->facing;
                }break;
                case 32:{ //read neighbour genome
                        struct Position pos = getNeighbour(x,y,z,facing);
                        tmpCell = &cells[pos.x][pos.y][pos.z];
                        if(accessOk(cell, tmpCell, reg,false)){
                                reg = tmpCell->genome[pointer];
                        }
                }break;
                case 33:{ //reproduce
                        if(output_buffer[0] != noRepOperation &&
                                        cell->energy >= cell->size * REPRODUCTION_COST_FACTOR){
                                cell->energy -= cell->size * REPRODUCTION_COST_FACTOR;
                                struct Position pos = getNeighbour(x,y,z,facing);
                                struct Cell *neighbour = &cells[pos.x][pos.y][pos.z];
                                if(accessOk(cell, neighbour, reg,false) && accessOk(cell, neighbour, reg,false)){
                                        if(reproduce(cell,neighbour,output_buffer)){
                                                cell->reproduced = 0;
                                        }
                                }
                        }
                        memset(output_buffer, noRepOperation, GENOME_SIZE * sizeof(uchar));
                        specCommands++;
                        if(specCommands >= SPECIAL_COMMANDS){
                                stop = true;
                        }
                }break;
                case 34: //create energy 2
                        if(cell->energy >= ENERGY2_CONVERSION_GAIN * 2){
                                cell->energy -= ENERGY2_CONVERSION_GAIN * 2;
                                cell->energy2++;
                        }
                        break;
                case 35:{//build wall
                    if(cell->generation >= LIVING){
                        struct Position pos = getNeighbour(x,y,z,facing);
                        tmpCell = &cells[pos.x][pos.y][pos.z];
                        if(accessOk(cell, tmpCell, reg,false)){
                            if(cell->energy2 >= 10 && cell->bad >= 3){
                                tmpCell->place->dead = true;
                                cell->energy2 -= 10;
                                cell->bad -= 3;
                            }
                        }
                    }
                }break;
                case 36:{//destroy wall
                        if(cell->generation >= LIVING){
                                struct Position pos = getNeighbour(x,y,z,facing);
                                tmpCell = &cells[pos.x][pos.y][pos.z];
                                if(tmpCell->place->dead && cell->energy2 >= 5 && cell->bad >= 2){
                                        tmpCell->place->dead = false;
                                        tmpCell->energy += 2*ENERGY2_CONVERSION_GAIN;
                                        cell->energy2 -= 5;
                                        cell->bad -= 2;
                                }
                        }
                }break;
                case 37:{ //special kill with energy2
                        if(cell->energy2 >= 2){
                            cell->energy2 -= 2;
                            struct Position pos = getNeighbour(x,y,z,facing);
                            tmpCell = &cells[pos.x][pos.y][pos.z];
                            if(cell->generation >= LIVING && tmpCell->energy2 < cell->energy2){
                                    killCell(tmpCell);
                                    specCommands++;
                            }
                            if(specCommands >= SPECIAL_COMMANDS){
                                    stop = true;
                            }
                        }
                    }
                break;
                case 38: //end
                        stop = true;
                        reproducing = false;
                        break;
                case 39: //end and reproduce
                        stop = true;
                        break;
                }
        }

        cell->facing = facing;

        output_pointer = 0;

        //jeah, we can reproduce something
        if(output_buffer[0] != noRepOperation && reproducing &&
                        cell->energy >= cell->size * REPRODUCTION_COST_FACTOR){
                cell->energy -= cell->size * REPRODUCTION_COST_FACTOR;
                struct Position pos = getNeighbour(x,y,z,facing);
                struct Cell *neighbour = &cells[pos.x][pos.y][pos.z];
                if(accessOk(cell, neighbour, reg,false) && accessOk(cell, neighbour, reg,false)){
                        if(reproduce(cell,neighbour,output_buffer)){
                                cell->reproduced = 0;
                        }else{
                                cell->reproduced++;
                        }
                }
        }else{
                cell->reproduced++;
        }

#ifdef MUST_REPRODUCE
        if(cell->generation >= LIVING && cell->reproduced > 4){
                killCell(cell);
        }
#endif
}

/**
 * Executes this cell// nanopond style
 */
void Simulation::executeCell1(int x, int y, int z){
	struct Cell *cell = &cells[x][y][z]; //current cell
		uchar inst; //current instruction
		int genome_pointer = 0; //pointer to the current genome instruction

		uchar output_buffer[GENOME_SIZE]; //outputbuffer, needed for reproducing
		bool stop = false;
		bool reproducing = true;
		struct Cell *tmpCell; //temporary cell

		memset(output_buffer, noRepOperation, GENOME_SIZE * sizeof(uchar));

		genome_pointer = 0;
		int pointer = 0;//general pointer
		int output_pointer = 0; //pointer to the outputbuffer
		uchar facing = cell->facing;
		int reg = 0; //internal register to be used for anything
		int temp = 0; //temp register
		uint executed = 0;
		uint specCommands = 0; //only allow a certain amout of kills

		//Execute cell until no more energy is left
		while(cell->energy && !stop && executed < MAX_EXECUTING){
			executed++;
			inst = cell->genome[genome_pointer];
			genome_pointer++;

			if(genome_pointer > GENOME_SIZE-1){
				genome_pointer = 0;
			}
			cell->energy--;

			switch(inst){
			case 0:{//Stop execution
				stop = true;
			}break;
			case 1://Don't reproduce further
				break;
			case 2://reset
				pointer = 0;
				reg = 0;
				temp = 0;
				output_pointer = 0;
				break;
			case 3: //pointer ++
				pointer++;
				if(pointer >= GENOME_SIZE ){
					pointer = 0;
				}
				break;
			case 4: //pointer --
				pointer--;
				if(pointer < 0){
					pointer = GENOME_SIZE - 1;
				}
				break;
			case 5: //register ++
				reg++;
				if(reg >= genomeOperations ){
					reg = 0;
				}
				break;
			case 6: //register --
				reg--;
				if(reg < 0 ){
					reg = genomeOperations - 1;
				}
				break;
			case 7: //read genome to register
				reg = cell->genome[pointer];
				break;
			case 8: //Modify genome
				cell->genome[pointer] = reg;
				break;
			case 9: //read output buffer to register
				reg = output_buffer[pointer];
				break;
			case 10:{ //write register to outputbuffer
				output_buffer[pointer] = reg;
			}break;
			case 11://while(register){
				if(!reg){
					int tempP = genome_pointer;
					uchar *comm = &cell->genome[genome_pointer];
					while(*comm != 10 &&
							cell->energy &&
							!stop){

						genome_pointer++;
						comm++;

						cell->energy--;

						if(genome_pointer == tempP ||
						   genome_pointer >= GENOME_SIZE){
							stop = true;
						}
					}

					genome_pointer++;
					if(genome_pointer >= GENOME_SIZE)
						genome_pointer = 0;
				}
				break;
			case 12://}
				if(reg){
					int tempP = genome_pointer;
					uchar *comm = &cell->genome[genome_pointer];
					while(*comm != 9 &&
							cell->energy &&
							!stop){
						genome_pointer--;
						comm--;
						cell->energy--;

						if(genome_pointer == tempP ||
								genome_pointer < 0){
							stop = true;
						}
					}

					genome_pointer++;
					if(genome_pointer >= GENOME_SIZE)
						genome_pointer = 0;
				}
				break;
			case 13://face to register
				facing = reg % DIRECTIONS;
				break;
			case 14:{ //skip next instruction, and swap with current reg
				genome_pointer++;

				if(genome_pointer > GENOME_SIZE-1){
					genome_pointer = 0;
				}
				char temp = cell->genome[pointer];
				cell->genome[pointer] = reg;
				reg = temp;
			}break;
			case 15:{ // kill
				struct Position pos = getNeighbour(x,y,z,facing);
				tmpCell = &cells[pos.x][pos.y][pos.z];
				if(cell->generation >= LIVING  &&
						randValue(4) == 0){
					killCell(tmpCell);
					specCommands++;
				}
				if(specCommands >= SPECIAL_COMMANDS){
					stop = true;
				}
			}break;
			case 16:{//share
				struct Position pos = getNeighbour(x,y,z,facing);
				tmpCell = &cells[pos.x][pos.y][pos.z];
				if(accessOk(cell, tmpCell, reg,true)){
					uint tmpEnergy = tmpCell->energy + cell->energy;
					tmpCell->energy = tmpEnergy / 2;
					cell->energy = tmpEnergy / 2;
				}
			}break;
			}
		}

		cell->facing = facing;

		output_pointer = 0;

		//jeah, we can reproduce something
		if(output_buffer[0] != noRepOperation && reproducing &&
				cell->energy >= cell->size * REPRODUCTION_COST_FACTOR){
			cell->energy -= cell->size * REPRODUCTION_COST_FACTOR;
			struct Position pos = getNeighbour(x,y,z,facing);
			struct Cell *neighbour = &cells[pos.x][pos.y][pos.z];
			if(accessOk(cell, neighbour, reg,false) && accessOk(cell, neighbour, reg,false)){
				if(reproduce(cell,neighbour,output_buffer)){
					cell->reproduced = 0;
				}else{
					cell->reproduced++;
				}
			}
		}else{
			cell->reproduced++;
		}

		#ifdef MUST_REPRODUCE
		if(cell->generation >= LIVING && cell->reproduced > 4){
			killCell(cell);
		}
		#endif
}

/**
 * reproduce cell.
 * Mutations are introduced
 * return true if cell has successfully reproduced (if false, only a small
 * part has been reproduced)
 */
bool Simulation::reproduce(struct Cell *cell, struct Cell *neighbour,uchar *output_buffer){

	if(neighbour->energy == 0)
		return false;

	int loop = 0;
	int i = 0;
	bool stoped = false;
	int copied = 0;

	int stops = 0;

	for(i = 0; i < GENOME_SIZE && loop < GENOME_SIZE; i++){
		if(output_buffer[loop] == noRepOperation || stops == 4){
			stoped = true;
			break;
		}

		if(output_buffer[loop] == GENOME_SIZE-1){
			stops++;
		}else{
			stops = 0;
		}

#ifdef REPRODUCTION_ERRORS
                if(__builtin_expect(!randValue(MUTATION_RATE_REPRODUCTION), false)){
			switch(randValue(4)){
			case 0://command replacement
				neighbour->genome[i] = randomOperation();
                        break;
			case 1://duplication or removal
				loop = randValue(GENOME_SIZE);
                        break;
			case 2:{//remove command
				loop++;
                        }break;
			case 3:{//insert command
				loop--;
                        }break;
			}
		}else{
#endif
			neighbour->genome[i] = output_buffer[loop];

#ifdef REPRODUCTION_ERRORS
		}
#endif

		loop++;
		copied++;
	}


	if(i < GENOME_SIZE - 1 && i > GENOME_SIZE / 5){
		memset(neighbour->genome +i*sizeof(uchar),
				genomeOperations - 1 ,
				((GENOME_SIZE - 1) - i) * sizeof(uchar));
	}

	if(copied >= MIN_COPY){
                if(neighbour->id && neighbour->generation >= LIVING){
			neighbour->energy += neighbour->size;
			totalLiving--;
		}

		if(cell->id == 0){
			cell->id = ++cellid;
			cell->lineage = cell->id;
		}

		neighbour->id = ++cellid;

		neighbour->parent = cell->id;

		neighbour->generation = cell->generation + 1;

		if(neighbour->generation >= LIVING){
			totalLiving++;
		}

                neighbour->injected = cell->injected;

		neighbour->lineage = cell->lineage;

		neighbour->brain = 0;

		neighbour->size = copied;

		neighbour->homePond = cell->homePond;
		return true;
	}

	return false;
}

/**
 * Initialize each cell
 */
void Simulation::init(){
	catas = false;
	int x = 0;
	int y = 0;
	int z = 0;

        memset(cells, 0, sizeof(struct Cell)*WORLD_X*WORLD_Y*WORLD_Z);

	for(x = 0; x < WORLD_X; x++){
		for(y = 0; y < WORLD_Y; y++){
			for(z = 0; z < WORLD_Z; z++){
				killCell(&cells[x][y][z]);

				cells[x][y][z].energy = ENERGY_ADDED;
				cells[x][y][z].energy2 = 0;
				cells[x][y][z].bad = 1;
				cells[x][y][z].place = &world[x][y][z];
			}
		}
	}

	struct Place *place;
	for(x = 0; x < WORLD_X; x++){
		for(y = 0; y < WORLD_Y; y++){
			for(z = 0; z < WORLD_Z; z++){
				place = &world[x][y][z];
				place->dead = false;
			}
		}
	}

	int lines = 0;
	while(lines < LANDSCAPE_LINES){
		struct Position start;
		start.x = randomX();
		start.y = randomY();
		start.z = randomZ();

		struct Position end;
		end.x = randomX();
		end.y = randomY();
		end.z = randomZ();

		x = start.x;
		y = start.y;
		z = start.z;
		while(x != end.x || y != end.y){
			world[x][y][z].dead = true;
			cells[x][y][z].energy = 0;
			cells[x][y][z].bad = 0;

			if(x < end.x){
				x++;
			}else if(x > end.x){
				x--;
			}

			if(y < end.y){
				y++;
			}else if(y > end.y){
				y--;
			}

			if(z < end.z){
				z++;
			}else if(z > end.z){
				z--;
			}
		}

		lines++;
	}

	initialized = true;
        totalLiving = 0;
}

/**
 * mutates the whole genome
 */
void Simulation::mutateCell(struct Cell *cell){

	int max = cell->bad;
	if(max > GENOME_SIZE / 6){
		max = GENOME_SIZE / 6;
	}

	if(max){
		max++;
                max = randomNumber() % max;
	}

	for(int i = 0; i < max; i++){
		int pos = randValue(GENOME_SIZE / 3);
		cell->genome[pos] = randomOperation();
	}

	mutated += max;
}

/**
 * returns a random operation
 */
inline uchar Simulation::randomOperation(){
        return uchar(randomNumber() * randScale * genomeOperations);
}

inline int Simulation::randomX(){
        return int(randomNumber() * randScaleX);
}

inline int Simulation::randomY(){
        return int(randomNumber() * randScaleY);
}

inline int Simulation::randomZ(){
	return 0;
        //return int(randomNumber() * randScale * WORLD_Z);
}

inline int Simulation::randValue(int value){
	return int(bigrand() * randScaleBig * value);
}

/**
 * returns the cell at the specified position
 */
struct Cell *Simulation::cell(int x, int y, int z){
	return &cells[x][y][z];
}

/**
 * creates a disaster
 */
void Simulation::disaster(){
	int type = 0;
	switch(randValue(6)){
	case Meteor:
		type = Meteor;
		qDebug() << "Meteor hit pond" << myId;
		//Meteor that kills most live
		break;
	case Poison:
		qDebug() << "Poison meteor hit pond"<< myId;
		type = Poison;
                //Meteor that kills most live and poisons the place
		break;
	case Hunger:
		qDebug() << "Hunger hit pond"<< myId;
		type = Hunger;
		break;
	case Killer:
		qDebug() << "Big Killer hit pond"<< myId;
		type = Killer;
		//Kill all big cells, small survive
		break;
	case Living:
		qDebug() << "Living meteor hit pond"<< myId<<"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!";
		type = Living;
		break;
	case Flood:
		qDebug() << "Flood hit pond"<< myId;
		type = Flood;
		break;
	}

	int x,y;

	x = randomX();
	y = randomY();

	qDebug() << type << x << y;

	int realX, realY, realZ;
	realZ = 0; //special case anyway, what to do in a 3d env?

	int size = randValue(30) + 70;

        if(type != Living && randValue(10) == 0){ //10% chance of a big disaster
		if(randValue(4) == 0){ // again, 2% chance for a huge disaster
			size *= 6;
		}else{
			size *= 3;
		}
	}

	QQueue <struct Cell>*tempVoyagers = new QQueue<struct Cell>();

	for(int xLoop = x - size / 2; xLoop < x + size / 2; xLoop++){

		for(int yLoop = y - size / 2; yLoop < y + size / 2; yLoop++){
			realX = xLoop % WORLD_X;
			realY = yLoop % WORLD_Y;

			if(realX < 0)
				realX = WORLD_X + realX;
			if(realY < 0)
				realY = WORLD_Y + realY;

			if(world[realX][realY][realZ].dead)
				continue;

			switch(type){
			case Meteor:{
				if(randValue(40)){
					killCell(&cells[realX][realY][realZ]);
				}
			}break;
			case Poison:{
				if(randValue(20)){
					killCell(&cells[realX][realY][realZ]);
					cells[realX][realY][realZ].bad = 10;
				}
			}break;
			case Hunger:{
				cells[realX][realY][realZ].energy /= 10;
				cells[realX][realY][realZ].energy2 /= 10;
			}break;
			case Killer:{
				if(cells[realX][realY][realZ].size > GENOME_SIZE / 6){
					killCell(&cells[realX][realY][realZ]);
				}
			}break;
			case Flood:{
				if(cells[realX][realY][realZ].size < GENOME_SIZE / 6){
					killCell(&cells[realX][realY][realZ]);
					cells[realX][realY][realZ].energy *= 3;
				}
			}break;
			case Living:{
				if(randValue(300) == 0){
					genepoolblocker->acquire(1);
					struct Cell voyager = cells[realX][realY][realZ];
					if(!genepool->isEmpty()){ //replace current cell with one of the pool
						cells[realX][realY][realZ] = genepool->dequeue();
						cells[realX][realY][realZ].place = &world[realX][realY][realZ];
					}
					//if replaced cell lives, put it in the pool
                                        if(voyager.generation >= LIVING){
						tempVoyagers->enqueue(voyager);
					}
					genepoolblocker->release(1);
				}else{
					killCell(&cells[realX][realY][realZ]);
				}
			}break;
			}

		}
	}

	if(type == 4){
		genepoolblocker->acquire(1);
		int max = 10;
		while(!tempVoyagers->isEmpty() && max){
			if(genepool->size() > 70 ){ //only hold 70 cells, remove one if too many
				genepool->removeAt(randValue(genepool->size()));
			}
			genepool->enqueue(tempVoyagers->dequeue());
			max--;
		}
		genepoolblocker->release(1);
	}

	delete tempVoyagers;

}


/**
 * returns the neighbour in the specified direction
 * wraps around edges
 */
struct Position Simulation::getNeighbour(int x, int y, int z, uchar direction){

	switch(direction){
	case NORTH:{
		y--;
                if(__builtin_expect (y < 0, false)){
			y = WORLD_Y - 1;
		}
	}
		break;
	case SOUTH:{
		y++;
		if(__builtin_expect (y >= WORLD_Y,false)){
			y = 0;
		}
	}
		break;
	case WEST:{
		x--;
		if(__builtin_expect (x < 0,false)){
			x = WORLD_X-1;
		}
	}
		break;
	case EAST:{
		x++;
		if(__builtin_expect (x >= WORLD_X,false)){
			x = 0;
		}
	}
		break;
	case UP:{
		z++;
		if(__builtin_expect (z >= WORLD_Z,false)){
			z = WORLD_Z - 1;
		}
	}
		break;
	case DOWN:{
		z--;
		if(__builtin_expect (z < 0,false)){
			z = 0;
		}
	}
		break;
	}

	struct Position pos;
	pos.x = x;
	pos.y = y;
	pos.z = 0;//z;
	return pos;
}

void Simulation::saveWorld(QString file){
	QFile out(file);
	out.open(QIODevice::WriteOnly | QIODevice::Truncate);
	qDebug() << sizeof(cells);
	QByteArray tempCells((char *)cells,sizeof(cells));
	out.write(tempCells);
	QByteArray tempWorld((char *)world,sizeof(world));
	out.write(tempWorld);

	qDebug() << "saved" << file;
	out.close();
}

void Simulation::loadWorld(QString file){
	QFile in(file);
	in.open(QIODevice::ReadOnly);

	QByteArray tempCells = in.read(sizeof(cells));
	memcpy(*cells, tempCells.data(), sizeof(cells));

	QByteArray tempWorld = in.read(sizeof(world));
	memcpy(*world, tempWorld.data(), sizeof(world));

	for(int x = 0; x < WORLD_X; x++){
		for(int y = 0; y < WORLD_Y; y++){
			for(int z = 0; z < WORLD_Z; z++){
				cells[x][y][z].place = &world[x][y][z];
			}
		}
	}

	qDebug() << "loaded" << file;
	in.close();
	initialized = true;
	catas = true;
}
