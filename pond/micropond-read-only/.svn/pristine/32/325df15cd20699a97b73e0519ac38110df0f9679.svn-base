/*
 * CellEditor.cpp
 *
 *  Created on: 06.08.2008
 *      Author: asraniel
 */

#include "CellEditor.h"

CellEditor::CellEditor(Simulation *sim) {
	simu = sim;

	QGridLayout *layout = new QGridLayout();

	QPushButton *add = new QPushButton("Add");
	connect(add, SIGNAL(clicked()), this, SLOT(add()));
	QPushButton *cancel = new QPushButton("Cancel");
	connect(cancel, SIGNAL(clicked()), this, SLOT(cancel()));

	genome = new QTextEdit();

	layout->addWidget(genome,0,0,1,2);
	layout->addWidget(add,1,0);
	layout->addWidget(cancel,1,1);

	setLayout(layout);
}

CellEditor::~CellEditor() {
	// TODO Auto-generated destructor stub
}

void CellEditor::add(){
	uchar gen[100];
	int size = 0;

	QString text = genome->toPlainText();

	QStringList lines = text.split("\n");

	for(int i = 0; i < lines.size();i++){
		gen[i] = (uchar)lines.at(i).toInt();
		size++;
	}

	simu->addCell(gen, size);
}

void CellEditor::cancel(){
	reject();
}
