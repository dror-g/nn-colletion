#ifndef WINDOW_H_
#define WINDOW_H_

#include <QtGui>

#include "Renderer.h"
#include "Simulation.h"
#include "CreatureBar.h"
#include "Incoming.h"
#include "Outgoing.h"

#define THREADS 1
#define STAT_INTERVAL 1000

#define DEVELOPER_MODE

class Window: public QMainWindow
{
	Q_OBJECT
public:
	Window(int threads);
	virtual ~Window();
	void initGui();
	void closeEvent ( QCloseEvent * event );

public slots:
	void valueChanged(int val);
	void ageView();
	void genomeView();
	void lineageView();
	void logoView();
	void sizeView();
	void energyView();
	void energy2View();
	void toxicView();
        void injectedView();
	void close();
	void load(QString file);
	void save(QString file);
	void selectPond(QAction * pond);
	void stat();
	void savePond();
	void loadPond();
	void resetPond();
	void resetAllPonds();
	void configNetwork();
	void addCell();

private:
	void closing();

	Simulation *simulation;
	Renderer *renderer;
	CreatureBar *creatureBar;
	QSlider *slider;
	QActionGroup *viewsGroup;
	QActionGroup *pondsGroup;
	QSemaphore *sema; //controls the rendering and loading
	QList <Simulation *>*simus;
	QQueue <struct Cell>*genepool;
	QSemaphore *genepoolblocker;
	Incoming *incRequests;
	Outgoing *outRequests;
};

#endif /*WINDOW_H_*/
