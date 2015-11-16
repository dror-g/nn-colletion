/*
 * CellEditor.h
 *
 *  Created on: 06.08.2008
 *      Author: asraniel
 */

#include <QtGui>
#include "Simulation.h"

#ifndef CELLEDITOR_H_
#define CELLEDITOR_H_

class CellEditor: public QDialog
{
	Q_OBJECT

public:
	CellEditor(Simulation *sim);
	virtual ~CellEditor();
public slots:
	void add();
	void cancel();

private:
	Simulation *simu;
	QTextEdit *genome;
};

#endif /* CELLEDITOR_H_ */
