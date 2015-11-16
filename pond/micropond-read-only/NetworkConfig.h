#ifndef NETWORKCONFIG_H_
#define NETWORKCONFIG_H_

#include <QtGui>
#include "Outgoing.h"

class NetworkConfig: public QDialog
{
	Q_OBJECT
public:
	NetworkConfig(Outgoing *outgoing);
	virtual ~NetworkConfig();
	
public slots:
	void save();
	void add();
	void remove();
	
private:
	void addPond(int index);
	
	Outgoing *out;
	QLineEdit *host;
	QSpinBox *port;
	QListWidget *list;
};

#endif /*NETWORKCONFIG_H_*/
