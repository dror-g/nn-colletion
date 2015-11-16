#ifndef INCOMING_H_
#define INCOMING_H_

#include <QtNetwork>

#include "Simulation.h"

#define PORT 5443

/**
 * This class accepts incoming requests for a cell exchange
 */
class Incoming: public QObject
{
	Q_OBJECT
	
public:
	Incoming(QQueue <struct Cell>*pool,QSemaphore *geneblocker);
	virtual ~Incoming();

public slots:
	void accept();
	
private:
	QTcpServer *server;
	uint port;
	
	QQueue <struct Cell>*genepool;
	QSemaphore *genepoolblocker;
};

#endif /*INCOMING_H_*/
