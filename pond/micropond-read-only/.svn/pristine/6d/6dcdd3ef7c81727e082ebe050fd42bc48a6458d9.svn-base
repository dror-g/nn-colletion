#ifndef CREATUREBAR_H_
#define CREATUREBAR_H_

#include <QtGui>
#include "Simulation.h"

#define PREVIEW_SIZE 50

class CreatureBar: public QDockWidget
{
	Q_OBJECT
public:
	CreatureBar();
	virtual ~CreatureBar();
public slots:
	void cellSelected(struct Cell cell);
	
private:
	QString operationName(uchar operation);
	QLabel *generation;
	QLabel *id;
	QLabel *lineage;
	QLabel *picture;
	QLabel *size;
	QLabel *toxic;
	QTextEdit *genome;
};

#endif /*CREATUREBAR_H_*/
