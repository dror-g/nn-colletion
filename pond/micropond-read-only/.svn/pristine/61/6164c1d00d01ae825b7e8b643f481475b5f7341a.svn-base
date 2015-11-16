#ifndef RENDERER_H_
#define RENDERER_H_

#include <QtGui>
#include "Simulation.h"

#define UPDATE_INTERVAL 2000

#define GENERATION 0
#define GENOME 1
#define LINEAGE 2
#define HOME 3
#define LANDSCAPE 4
#define ENERGY 5
#define ENERGY2 6
#define BAD 7
#define INJECTED 8

#define RENDERMODES 9

#define LIVING_CELL 3

#define SHOW_LANDSCAPE true

// ffmpeg -r 10 -qscale 1 -i asdf%d.png micropond.avi
//#define SAVE_PICTURES


class Renderer: public QLabel
{
	Q_OBJECT
public:
	Renderer(Simulation *sim,QSemaphore *sem);
	virtual ~Renderer();

	void mousePressEvent ( QMouseEvent * event );
	static QColor getColor(struct Cell *cell, int mode);
	void setSimulation(Simulation *sim){
		simulation->resume();
		simulation = sim;
	}

signals:
	void cellSelected(struct Cell cell);

public slots:
	void update();
	void changeColorMode(int mode);

private:
	void updatePicture();
	Simulation *simulation;
	int colorMode;
	QSemaphore *sema; //controls the rendering and loading

#ifdef SAVE_PICTURES
	int imageCounter;
#endif
};

#endif /*RENDERER_H_*/
