# OS
FROM ubuntu:16.04

# Install Fortran & C Compilers and autoconf
RUN cd $HOME && mkdir install && apt-get update && apt-get -y install build-essential gfortran m4 wget

# Install MPI Libraries and Software
RUN cd $HOME/install && wget http://www.mpich.org/static/downloads/3.3/mpich-3.3.tar.gz && \
	tar -zxvf mpich-3.3.tar.gz && cd mpich-3.3 && \
	./configure -disable-fast CFLAGS=-O2 FFLAGS=-O2 CXXFLAGS=-O2 FCFLAGS=-O2 -prefix=/opt/mpich3 CC=gcc FC=gfortran F77=gfortran && make && make install

# Install WGRIB2 package from NCEP
RUN cd $HOME/install && wget https://www.ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz && tar -zxvf wgrib2.tgz && cd grib2 && \
	sed -i '118s/USE_NETCDF3=.*/USE_NETCDF3=0/' makefile && \
	sed -i '119s/USE_NETCDF4=.*/USE_NETCDF4=0/' makefile && \
	sed -i '120s/USE_REGEX=.*/USE_REGEX=1/' makefile && \
	sed -i '121s/USE_TIGGE=.*/USE_TIGGE=1/' makefile && \
	sed -i '122s/USE_MYSQL=.*/USE_MYSQL=0/' makefile && \
	sed -i '123s/USE_IPOLATES=.*/USE_IPOLATES=3/' makefile && \
	sed -i '124s/USE_SPECTRAL=.*/USE_SPECTRAL=0/' makefile && \
	sed -i '125s/USE_UDF=.*/USE_UDF=0/' makefile && \
	sed -i '126s/USE_OPENMP=.*/USE_OPENMP=0/' makefile && \
	sed -i '127s/USE_PROJ4=.*/USE_PROJ4=0/' makefile && \
	sed -i '128s/USE_WMO_VALIDATION=.*/USE_WMO_VALIDATION=0/' makefile && \
	sed -i '129s/DISABLE_TIMEZONE=.*/DISABLE_TIMEZONE=0/' makefile && \
	sed -i '130s/MAKE_FTN_API=.*/MAKE_FTN_API=1/' makefile && \
	sed -i '131s/DISABLE_ALARM=.*/DISABLE_ALARM=0/' makefile && \
	sed -i '133s/USE_G2CLIB=.*/USE_G2CLIB=0/' makefile && \
	sed -i '134s/USE_PNG=.*/USE_PNG=0/' makefile && \
	sed -i '135s/USE_JASPER=.*/USE_JASPER=0/' makefile && \
	sed -i '136s/USE_AEC=.*/USE_AEC=0/' makefile && \
	make CC=gcc FC=gfortran && make CC=gcc FC=gfortran lib && cd $HOME/install && mv grib2 /opt

# Install Curl libraries
RUN cd $HOME/install && wget https://curl.haxx.se/download/curl-7.65.0.tar.gz && tar -xzvf curl-7.65.0.tar.gz && cd curl-7.65.0 && \
	CC=gcc FC=gfortran ./configure --without-zlib && make && make install

# Install zlib
RUN cd $HOME/install && wget https://www.zlib.net/zlib-1.2.11.tar.gz && tar -zxvf zlib-1.2.11.tar.gz && cd zlib-1.2.11 && \
	FC=gfortran CC=gcc ./configure && make && make install

# Install the NetCDF C libraries and packages
RUN cd $HOME/install && wget https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-c-4.7.0.tar.gz && export LD_LIBRARY_PATH=/usr/local/lib && \
	tar -xzvf netcdf-c-4.7.0.tar.gz && cd netcdf-c-4.7.0 && \
	FC=gfortran CC=gcc ./configure --enable-fortran --disable-netcdf-4 --disable-share LT_SYS_LIBRARY_PATH=/usr/local/lib && make && make check && make install

# Install the NetCDF Fortran libraries and packages
RUN cd $HOME/install && wget https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-fortran-4.4.5.tar.gz && tar -xzvf netcdf-fortran-4.4.5.tar.gz && \
	cd netcdf-fortran-4.4.5 && export LD_LIBRARY_PATH=/usr/local/lib && FC=gfortran CC=gcc ./configure --enable-fortran --disable-netcdf-4 --disable-shared && make && make check && make install

# Configure ssh (multi-host)
RUN apt-get -y install dnsutils openssh-server
COPY sshconfig /root/.ssh/config
RUN mkdir -p /var/run/sshd \
    && ssh-keygen -A \
    && sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config \
    && sed -i 's/#RSAAuthentication yes/RSAAuthentication yes/g' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config \
    && ssh-keygen -f /root/.ssh/id_rsa -t rsa -N '' \
    && chmod 600 /root/.ssh/config \
    && chmod 700 /root/.ssh \
    && cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys 
RUN echo 'root:brams' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Copy BRAMS to container (files: tables/, src/, doc/, build/, variables.csv, README, RAMSIN_meteo-only, RAMSIN_meteo-chem, jules.in, HISTORICO, gfdl_cloud_microphysics_nml)
COPY brams.tgz /root

# Making BRAMS' Model
RUN cd $HOME && tar -zxvf brams.tgz && cd BRAMS && sed -i 's/ICFILEPREFIX/ICFILETYPE/' RAMSIN_meteo-* && cd build && \
	./configure -program-prefix=BRAMS -prefix=$HOME -enable-jules -with-chem=RELACS_TUV -with-aer=SIMPLE -with-fpcomp=/opt/mpich3/bin/mpif90 -with-cpcomp=/opt/mpich3/bin/mpicc -with-fcomp=gfortran -with-ccomp=gcc --with-wgrib2=/opt/grib2/lib --with-netcdf=/usr/local/ && make && make install

# Copy script to container
COPY run-brams /root

# Clean up unnecessary files and give execution permission to script
RUN cd $HOME && rm -rf install/ BRAMS/ brams.tgz && apt-get autoremove && apt-get clean && chmod +x run-brams

#
WORKDIR /root
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]