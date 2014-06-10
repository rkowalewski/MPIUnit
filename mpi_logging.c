#include <mpi.h>
#include <stdio.h>
#include "logging.h"

int main(int argc, char** argv) {
  // Initialize the MPI environment
  MPI_Init(NULL, NULL);
  // Get the number of processes
  int world_size;
  MPI_Comm_size(MPI_COMM_WORLD, &world_size);

  // Get the rank of the process
  int world_rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

  EXPECT_GT(world_rank, world_size, 0);

  EXPECT_VALUE_IN_RANGE(world_rank, world_rank, 0, world_size);

  EXPECT_EQ(world_rank, INT, 1, world_size);

  PUTVAL(world_rank, "nprocs", world_size, %d );
  PUTVAL(world_rank, "myrank", world_rank, %d);

  for (int i=0; i<world_size; i++) {
    EXPECT_EQ(world_rank, INT, world_size, GETVAL("nprocs", i));
    EXPECT_EQ(world_rank, INT, i, GETVAL("myrank", i));
  }

  // Finalize the MPI environment.
  MPI_Finalize();
}
