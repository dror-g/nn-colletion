#include "CreatureBar.h"
#include "Renderer.h"

CreatureBar::CreatureBar()
{
	QVBoxLayout *layout = new QVBoxLayout;
	QWidget *dockWidget = new QWidget;
	dockWidget->setLayout(layout);

	picture = new QLabel();

	QPixmap pix( PREVIEW_SIZE, PREVIEW_SIZE);
	pix.fill(Qt::white);

	picture->setPixmap(pix);

	layout->addWidget(picture);

	id = new QLabel("ID: ");
	layout->addWidget(id);

	generation = new QLabel("Generation: ");
	layout->addWidget(generation);

	lineage = new QLabel("Lineage: ");
	layout->addWidget(lineage);

	size = new QLabel("Size: ");
	layout->addWidget(size);

	toxic = new QLabel("Toxic: ");
	layout->addWidget(toxic);

	genome = new QTextEdit();
	genome->setReadOnly(true);
	layout->addWidget(genome);

	//layout->addStretch(1);

	setWidget(dockWidget);
	setMinimumWidth(250);
        setMaximumWidth(300);
}

QString CreatureBar::operationName(uchar operation){

	switch(operation){
	case 0:
		return "reset";
		break;
	case 1: //pointer ++
		return "pointer++";
		break;
	case 2: //pointer --
		return "pointer--";
		break;
	case 3: //register ++
		return "register++";
		break;
	case 4: //register --
		return "register--";
		break;
	case 5: //read genome to register
		return "read genome";
		break;
	case 6: //write register to outputbuffer
		return "write to buffer";
		break;
	case 7: //read output buffer to register
		return "read buffer";
		break;
	case 8: //look into direction specified in the register
		return "face to register";
		break;
	case 9://while(register){
		return "while(register){";
		break;
	case 10://}
		return "}";
		break;
	case 11:
		return "NOP & NOREP";
		break;
	case 12: //move
		return "move to facing";
		break;
	case 13: // kill
		return "kill facing cell";
		break;
	case 14://nop
		return "remove bad";
		break;
	case 15://share
		return "share";
		break;
	case 16://swap temp
		return "swap";
		break;
	case 17://reset registers
		return "save reg in brain";
		break;
	case 18: //probe
                return "probe neighbour type";
		break;
	case 19: //end
		return "execute facing";
		break;
	case 20: //end
		return "recall brain";
		break;
	case 21: //end
		return "compare reg and temp";
		break;
	case 22: //end
		return "register = direction with most energy";
		break;
	case 23:
                return "inject code";
		break;
	case 24:
                return "convert energy2 to energy";
		break;
	case 25://end
		return "eject";
		break;
	case 26://end
		return "reg = random";
		break;
	case 27://end
		return "is outpointer == max?";
		break;
	case 28://end
		return "if(!reg)";
		break;
	case 29://end
		return "if(reg)";
		break;
	case 30://end
		return "reg = number of directions";
		break;
	case 31://end
		return "reg = neighbour facing";
		break;
	case 32://end
		return "Read neighbour genome";
		break;
	case 33://end
		return "reproduce";
		break;
	case 34://end
		return "create energy2";
		break;
	case 35://end
                return "build wall";
		break;
	case 36://end
                return "destroy wall";
		break;
        case 37://end
                return "special kill";
                break;
        case 38://end
		return "stop";
		break;
        case 39://end
		return "stop && reproduce";
		break;
	}
	return "NOT DEFINED"+QString::number(operation);
}

void CreatureBar::cellSelected(struct Cell cell){
	QPixmap pix( PREVIEW_SIZE, PREVIEW_SIZE);
	pix.fill(Renderer::getColor(&cell, 1));
	picture->setPixmap(pix);

	generation->setText("Generation: "+QString::number(cell.generation));
	id->setText("ID: "+QString::number(cell.id));
	lineage->setText("Lineage: "+QString::number(cell.lineage));
	size->setText("Size: "+QString::number(cell.size));
	toxic->setText("Toxic: "+QString::number(cell.bad));
	genome->clear();
	for(uint i = 0; i < cell.genome_size; i++){
            genome->append(QString::number(cell.genome[i])+" "+ operationName(cell.genome[i]));
	}
	genome->moveCursor(QTextCursor::Start, QTextCursor::MoveAnchor);
}

CreatureBar::~CreatureBar()
{
}
