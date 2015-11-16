#include "Window.h"
#include "NetworkConfig.h"
#include "CellEditor.h"

Window::Window(int threads)
{
	sema = new QSemaphore(1);
	genepool = new QQueue<struct Cell>();
	genepoolblocker = new QSemaphore(1);
	qsrand(time(NULL));

	simus = new QList<Simulation *>();
	for(int i = 0; i < threads; i++){
                qDebug() <<"creating simulation"<<i;
                Simulation *temp = new Simulation(genepool,genepoolblocker,i);
		temp->start();
		simus->append(temp);
	}

	simulation = simus->at(0); //select first thread as default
	renderer = new Renderer(simulation,sema);
	stat();

	incRequests = new Incoming(genepool,genepoolblocker);
	outRequests = new Outgoing(genepool,genepoolblocker);
}

void Window::stat(){
	unsigned long total = 0;
	unsigned long totalLiving = 0;
	for(int i = 0; i < simus->size(); i++){
		uint temp = simus->at(i)->executed();
		total += temp;
                //qDebug() << "pond" << i << "executed:" << temp;

		temp = simus->at(i)->getLiving();
		totalLiving += temp;
	}
        //qDebug() << "total executed:" << total;
        //qDebug() << "living:" << totalLiving;
        setWindowTitle("Micropond    CPS: " + QString::number(total) +" AL: "+QString::number(totalLiving));
	QTimer::singleShot(STAT_INTERVAL, this, SLOT(stat()));
}

void Window::initGui(){

	renderer->update();

	slider = new QSlider();
	slider->setRange(0, simulation->getMaxEnergyAdd());
	slider->setValue(simulation->getEnergyAdd());
	slider->setOrientation(Qt::Horizontal);

	connect(slider, SIGNAL(valueChanged(int)), this, SLOT(valueChanged(int)));

	QWidget *central = new QWidget();
	QBoxLayout *layout = new QBoxLayout(QBoxLayout::TopToBottom);
	layout->addWidget(renderer);
	layout->addWidget(slider);
	central->setLayout(layout);

	setCentralWidget(central);

	creatureBar = new CreatureBar();
	creatureBar->setFeatures(QDockWidget::DockWidgetMovable);

	connect(renderer,SIGNAL(cellSelected(struct Cell)),
			creatureBar,SLOT(cellSelected(struct Cell)));

	addDockWidget(Qt::RightDockWidgetArea,creatureBar);


	//MENU
	QMenuBar *menuBar = new QMenuBar();
	QMenu *file = new QMenu("File");
	QAction *close = new QAction("Close",this);
	connect(close , SIGNAL(triggered()), this, SLOT(close()));

	QAction *save = new QAction("Save pond as",this);
	connect(save , SIGNAL(triggered()), this, SLOT(savePond()));

	QAction *load = new QAction("Load pond",this);
	connect(load , SIGNAL(triggered()), this, SLOT(loadPond()));

	QAction *reset = new QAction("Reset pond",this);
	connect(reset , SIGNAL(triggered()), this, SLOT(resetPond()));

	QAction *resetAll= new QAction("Reset all ponds",this);
	connect(resetAll , SIGNAL(triggered()), this, SLOT(resetAllPonds()));

	file->addAction(save);
	file->addAction(load);
	file->addAction(reset);
	file->addAction(resetAll);
	file->addAction(close);

	QMenu *views = new QMenu("Viewmode");

	viewsGroup = new QActionGroup(this);
	viewsGroup->setExclusive(true);

	QAction *age = new QAction("Age",viewsGroup);
	connect(age, SIGNAL(triggered()), this, SLOT(ageView()));
	age->setCheckable(true);

	QAction *genome = new QAction("Genome",viewsGroup);
	connect(genome, SIGNAL(triggered()), this, SLOT(genomeView()));
	genome->setCheckable(true);
	genome->setChecked(true);

	QAction *lineage = new QAction("Lineage",viewsGroup);
	connect(lineage, SIGNAL(triggered()), this, SLOT(lineageView()));
	lineage->setCheckable(true);

	QAction *logo = new QAction("Home pond",viewsGroup);
	connect(logo, SIGNAL(triggered()), this, SLOT(logoView()));
	logo->setCheckable(true);

	QAction *size = new QAction("Size",viewsGroup);
	connect(size, SIGNAL(triggered()), this, SLOT(sizeView()));
	size->setCheckable(true);

	QAction *energy = new QAction("Energy",viewsGroup);
	connect(energy, SIGNAL(triggered()), this, SLOT(energyView()));
	energy->setCheckable(true);

	QAction *energy2 = new QAction("Energy 2",viewsGroup);
	connect(energy2, SIGNAL(triggered()), this, SLOT(energy2View()));
	energy2->setCheckable(true);

	QAction *toxic = new QAction("Toxics",viewsGroup);
        connect(toxic, SIGNAL(triggered()), this, SLOT(toxicView()));
	toxic->setCheckable(true);

        QAction *injected = new QAction("Injected",viewsGroup);
        connect(injected, SIGNAL(triggered()), this, SLOT(injectedView()));
        views->addActions(viewsGroup->actions());
        injected->setCheckable(true);

	pondsGroup = new QActionGroup(this);
	pondsGroup->setExclusive(true);
	connect(pondsGroup , SIGNAL(triggered(QAction *)), this, SLOT(selectPond(QAction *)));
	QMenu *ponds = new QMenu("Ponds");
	for(int i = 0; i < simus->size(); i++){
		QAction *pond = new QAction(QString::number(i),pondsGroup);
		pond->setCheckable(true);
		if(i == 0)
			pond->setChecked(true);
	}
	ponds->addActions(pondsGroup->actions());

	//Options menu
	QMenu *options = new QMenu("Options");
	QAction *remote = new QAction("Remote ponds",this);
	connect(remote, SIGNAL(triggered()), this, SLOT(configNetwork()));
	options->addAction(remote);
#ifdef DEVELOPER_MODE

	QAction *addCell = new QAction("Add cell",this);
	connect(addCell, SIGNAL(triggered()), this, SLOT(addCell()));
	options->addAction(addCell);
#endif

	menuBar->addMenu(file);
	menuBar->addMenu(views);
	menuBar->addMenu(ponds);
	menuBar->addMenu(options);
	setMenuBar(menuBar);

	resize(200,200);
	show();
}

void Window::valueChanged(int val){
	simulation->setEnergyAdd((uint) val);
}

void Window::closeEvent( QCloseEvent * event ){
	closing();
	event->accept();
}

void Window::close(){
	closing();
	qApp->quit();
}

void Window::closing(){
	renderer->close();
	for(int i = 0; i < simus->size() ; i++){
		simus->at(i)->resume();
		simus->at(i)->stopIt();
                while(simus->at(i)->isRunning()){};
	}
}

Window::~Window()
{
}

void Window::ageView(){
	renderer->changeColorMode(0);
}

void Window::genomeView(){
	renderer->changeColorMode(1);
}

void Window::lineageView(){
	renderer->changeColorMode(2);
}

void Window::logoView(){
	renderer->changeColorMode(3);
}

void Window::sizeView(){
	renderer->changeColorMode(4);
}

void Window::energyView(){
	renderer->changeColorMode(5);
}

void Window::energy2View(){
	renderer->changeColorMode(6);
}

void Window::toxicView(){
	renderer->changeColorMode(7);
}

void Window::injectedView(){
        renderer->changeColorMode(8);
}

void Window::load(QString file){
	sema->acquire(1);
	simulation->resume();
	simulation->stopIt();
        while(!simulation->isFinished()){};
	simulation->loadWorld(file);
	simulation->start();

	slider->setRange(0, simulation->getMaxEnergyAdd());
	slider->setValue(simulation->getEnergyAdd());
	sema->release(1);
}

void Window::save(QString file){
	sema->acquire(1);
	simulation->resume();
	simulation->stopIt();
        while(!simulation->isFinished()){};
	simulation->saveWorld(file);
	simulation->start();

	sema->release(1);
}

void Window::savePond(){
	QFileDialog::Options options;
	QString selectedFilter;
	QString fileName = QFileDialog::getSaveFileName(this,
	                             tr("Save pond"),
	                             QDir::homePath(),
								tr("Micropond files (*.pnd)"),
	                            &selectedFilter,
	                             options);
	if (!fileName.isEmpty()){
		if(!fileName.endsWith(".pnd")){
			fileName+=".pnd";
		}
		save(fileName);
	}
}

void Window::loadPond(){
	QFileDialog::Options options;
	QString selectedFilter;
	QString fileName = QFileDialog::getOpenFileName(this,
	                             tr("Load pond file"),
	                             QDir::homePath(),
	                             tr("Micropond files (*.pnd)"),
	                            &selectedFilter,
	                             options);
	if (!fileName.isEmpty()){
		load(fileName);
	}
}

void Window::resetPond(){
	sema->acquire(1);
	simulation->resume();
	simulation->stopIt();
        while(!simulation->isFinished()){};
	simulation->init();
	simulation->start();

	sema->release(1);
}

void Window::resetAllPonds(){
	sema->acquire(1);

	for(int i = 0; i < simus->size() ; i++){
		simus->at(i)->resume();
		simus->at(i)->stopIt();
                while(simus->at(i)->isRunning()){};
		simus->at(i)->init();
		simus->at(i)->start();
	}

	sema->release(1);
}

void  Window::configNetwork(){
	NetworkConfig networkConfig(outRequests);
	networkConfig.exec();

}

void Window::addCell(){
	CellEditor editor(simulation);
	editor.exec();
}

void Window::selectPond(QAction * pond){
	sema->acquire(1);
	int pondId = pond->text().toInt();
	simulation = simus->at(pondId);
	renderer->setSimulation(simulation);

	slider->setRange(0, simulation->getMaxEnergyAdd());
	slider->setValue(simulation->getEnergyAdd());

	sema->release(1);
}
