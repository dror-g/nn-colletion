#include "Outgoing.h"

Outgoing::Outgoing(QQueue <struct Cell>*pool,QSemaphore *geneblocker)
{
        genepool = pool;
        genepoolblocker = geneblocker;
 
        hosts = new QList <struct s_host>();
 
        //addHost("127.0.0.1",5443);
 
        QTimer::singleShot(INTERVAL, this, SLOT(transfer()));
        timeoutTimer = new QTimer();
        connect(timeoutTimer,SIGNAL(timeout()),this,SLOT(socketTimeout()));
}
 
 
Outgoing::~Outgoing()
{
}
 
 
void Outgoing::transfer(){
        socket = new QTcpSocket();
 
        if(!hosts->size()){
    		QTimer::singleShot(INTERVAL, this, SLOT(transfer()));
            return;
        }
 
        int target = qrand() % hosts->size();
 
        connect(socket,SIGNAL(readyRead()),this,SLOT(socketReadyRead()));
        socket->connectToHost(hosts->at(target).name, hosts->at(target).port, QIODevice::ReadOnly);
        //use a timeout timer to know for your timeout limit
        this->timeoutTimer->start(2000);
}
 
//a new slot for ready Read
void Outgoing::socketReadyRead()
{
        timeoutTimer->stop();
        qDebug() << "starting transfer";
        quint32 number = 55;
        QDataStream in(socket);
        in >> number;
 
        qDebug() << "receiving" << number << "cells";
 
        for(uint i = 0; i < number; i++){
        	struct Cell cell; 
 
	        int read = in.readRawData((char *)&cell,sizeof(cell));
	        if(read == sizeof(cell)){
                qDebug() << "got cell" << cell.id << cell.generation;
 
                genepoolblocker->acquire(1);
                genepool->enqueue(cell);
                genepoolblocker->release(1);
            }
        }
        socket->close();
        delete socket;
 
        QTimer::singleShot(INTERVAL, this, SLOT(transfer()));
}
 
//a new slot for timeout
void Outgoing::socketTimeout ()
{
        qDebug() << "could not connect to distant pond";
        socket->close();
        timeoutTimer->stop();
        delete socket;
        QTimer::singleShot(INTERVAL, this, SLOT(transfer()));
}
 
void Outgoing::deleteHost(int index){
        hosts->removeAt(index);
}
 
void Outgoing::addHost(QString host, quint16 port){
        struct s_host newHost;
        newHost.name = host;
        newHost.port = port;
        hosts->append(newHost);
}
 
struct s_host Outgoing::getHost(int index){
        return hosts->at(index);
}
