#ifndef OUTGOING_H_
#define OUTGOING_H_

#include <QtNetwork>

#include "Simulation.h"

#define INTERVAL 10000

struct s_host{
	QString name;
	quint16 port;
};

class Outgoing: public QObject
{
	Q_OBJECT
public:
	Outgoing(QQueue <struct Cell>*pool,QSemaphore *geneblocker);
	virtual ~Outgoing();
	
public slots:
	void transfer();
	void deleteHost(int index);
	void addHost(QString host, quint16 port);
	struct s_host getHost(int index);
	int size(){ return hosts->size();}
	void socketReadyRead();
	void socketTimeout ();
	
private:
	QQueue <struct Cell>*genepool;
	QSemaphore *genepoolblocker;
	QList <struct s_host>*hosts;
	QTimer *timeoutTimer;
	QTcpSocket *socket;
};

#endif /*OUTGOING_H_*/
