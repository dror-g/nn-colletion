#include "Incoming.h"


Incoming::Incoming(QQueue <struct Cell>*pool,QSemaphore *geneblocker)
{
	genepool = pool;
	genepoolblocker = geneblocker;
	
	port = PORT;
	server = new QTcpServer();
	connect(server, SIGNAL(newConnection()),this, SLOT(accept()));
	if(!server->listen(QHostAddress::Any,port)){
		qDebug() << "could not open server port";
	}
}

Incoming::~Incoming()
{
}

void Incoming::accept(){
	QTcpSocket *connection = server->nextPendingConnection();
	qDebug() << "looking at connection";
	if(connection){
		qDebug() << "received connection";
		genepoolblocker->acquire(1);
		quint32 number = 0;
		qDebug() << "poolsize:" << genepool->size();
		QByteArray block;
		QDataStream out(&block,QIODevice::WriteOnly);
		if(!genepool->isEmpty()){
			number = 1;
			qDebug() << number;
			out << number;
			
			struct Cell cell = genepool->dequeue();
			qDebug() << out.writeRawData((char *)&cell,sizeof(struct Cell));
			qDebug() << "sent one cell";
		}else{
			out << number;
		}
		connection->write(block);
		connection->flush();
		connection->waitForBytesWritten(-1);
		connection->close();
		genepoolblocker->release(1);
	}
}
