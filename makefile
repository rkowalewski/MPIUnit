EXECS=mpi_logging
MPICC?=mpicc
STD=c99

all: ${EXECS}

mpi_logging: mpi_logging.c
	${MPICC} -std=${STD} -save-temps -o mpi_logging mpi_logging.c

clean:
	rm -f ${EXECS} *.o *.i *.s
