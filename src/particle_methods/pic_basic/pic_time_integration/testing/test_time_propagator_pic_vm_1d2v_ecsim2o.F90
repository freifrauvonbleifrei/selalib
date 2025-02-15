! TODO: Use input from file to initialize and compare
! Unit test for symplectic splitting
! author: Benedikt Perse
program test_time_propagator_pic_1d2v_vm_ecsim2o
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#include "sll_memory.h"
#include "sll_working_precision.h"

  use sll_mpi, only: &
    MPI_SUM

  use sll_m_collective, only: &
    sll_s_boot_collective, &
    sll_o_collective_allreduce, &
    sll_s_halt_collective, &
    sll_v_world_collective

  use sll_m_constants, only: &
    sll_p_pi

  use sll_m_time_propagator_pic_vm_1d2v_ecsim2o, only: &
    sll_t_time_propagator_pic_vm_1d2v_ecsim2o

  use sll_m_particle_mesh_coupling_base_1d, only: &
    sll_p_galerkin, &
    sll_c_particle_mesh_coupling_1d

  use sll_m_particle_mesh_coupling_spline_1d, only: &
    sll_t_particle_mesh_coupling_spline_1d, &
    sll_s_new_particle_mesh_coupling_spline_1d_ptr

  use sll_m_maxwell_1d_base, only: &
    sll_c_maxwell_1d_base

  use sll_m_maxwell_1d_fem, only: &
    sll_t_maxwell_1d_fem

  use sll_m_particle_group_1d2v, only: &
    sll_t_particle_group_1d2v

  use sll_m_particle_group_base, only: &
    sll_t_particle_array

  implicit none
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ! Tolerance for comparison of real numbers: set it here!
  sll_real64, parameter :: EQV_TOL = 1.5e-11_f64

  ! Abstract particle group
  class(sll_t_particle_array), pointer :: particle_group
  class(sll_t_particle_group_1d2v), pointer :: pg

  ! Arrays for the fields
  sll_real64, pointer :: efield(:,:), efield_ref(:,:)
  sll_real64, pointer :: bfield(:), bfield_ref(:)
  sll_real64, pointer :: rho(:), rho_local(:)

  ! Abstract kernel smoothers
  class(sll_c_particle_mesh_coupling_1d), pointer :: kernel_smoother_0     
  class(sll_c_particle_mesh_coupling_1d), pointer :: kernel_smoother_1
  
  ! Maxwell solver 
  ! Abstract 
  class(sll_c_maxwell_1d_base), pointer :: maxwell_solver
  sll_real64 :: solver_tolerance = 1E-14_f64
  ! Specific Hamiltonian splitting
  type(sll_t_time_propagator_pic_vm_1d2v_ecsim2o) :: propagator
  
  ! Parameters
  sll_int32  :: n_particles
  sll_real64 :: eta_min, eta_max, domain(3)
  sll_int32  :: num_cells
  sll_real64 :: delta_t
  sll_int32  :: degree_smoother
  sll_int64  :: rnd_seed

  ! Helper 
  sll_int32  :: i_part, i_sp
  sll_real64 :: xi(3), wi(1)
  logical    :: passed
  sll_real64 :: error
  sll_int32  :: ierr   ! error code for SLL_ALLOCATE

  ! Reference
  sll_real64, allocatable :: particle_info_ref(:,:)
  sll_real64, allocatable :: particle_info_check(:,:)
   
  call sll_s_boot_collective()

  ! Set parameters
  n_particles = 2!10
  eta_min = 0.0_f64
  eta_max = 4.0_f64*sll_p_pi
  num_cells = 10
  delta_t = 0.1_f64
  degree_smoother = 3
  passed = .TRUE.
  rnd_seed = 10

  domain = [eta_min, eta_max, eta_max - eta_min]

  ! Initialize
  allocate(pg)
  call pg%init(n_particles, &
       n_particles ,1.0_f64, 1.0_f64, 1)
  allocate( particle_group )
  particle_group%n_species = 1
  i_sp = 1

  
  allocate( particle_group%group(1), source=pg )

  call particle_group%group(i_sp)%set_common_weight (1.0_f64)


  ! Initial particle information   
  ! Data produce with following call
  !call sll_s_particle_initialize_sobol_landau_2d2v(&
  !     particle_group, &
  !     [0.1_f64, 0.5_f64], &
  !     eta_min, &
  !     eta_max-eta_min, &
  !     [1.0_f64, 1.0_f64], &
  !     rnd_seed)
  !call sll_s_particle_initialize_sobol_landau_1d2v(particle_group, &
  !     [0.1_f64, 0.5_f64], domain(1),domain(3), &
  !     [1.0_f64, 1.0_f64] , rnd_seed)
  

  SLL_ALLOCATE(particle_info_ref(n_particles,4), i_part)
  SLL_ALLOCATE(particle_info_check(n_particles,4), i_part)
  particle_info_ref = 0.0_f64
  particle_info_ref = reshape([11.7809724509617_f64,        5.49778714378213_f64,       -1.53412054435254_f64,       0.15731068461017_f64,       0.15731068461017_f64,       -1.53412054435254_f64,        6.86367593760747_f64,        5.7026946767517_f64   ], [n_particles, 4])

  ! Initialize particles from particle_info_ref
  xi = 0.0_f64
  do i_part =1, n_particles
     xi(1) = particle_info_ref(i_part, 1) 
     call particle_group%group(i_sp)%set_x(i_part, xi)
     xi(1:2) = particle_info_ref(i_part, 2:3)
     call particle_group%group(i_sp)%set_v(i_part, xi)
     xi(1) = particle_info_ref(i_part, 4)
     call particle_group%group(i_sp)%set_weights(i_part, xi(1))
  end do

  call particle_group%group(i_sp)%set_common_weight (1.0_f64)

  ! Initialize kernel smoother    
  call sll_s_new_particle_mesh_coupling_spline_1d_ptr(kernel_smoother_1, &
       domain(1:2), num_cells, &
       n_particles, degree_smoother-1, sll_p_galerkin) 
  call sll_s_new_particle_mesh_coupling_spline_1d_ptr(kernel_smoother_0, &
       domain(1:2), num_cells, &
       n_particles, degree_smoother, sll_p_galerkin) 
  
  ! Initialize Maxwell solver
  allocate( sll_t_maxwell_1d_fem :: maxwell_solver )
  select type ( maxwell_solver )
  type is ( sll_t_maxwell_1d_fem )
     call maxwell_solver%init( [eta_min, eta_max], num_cells, &
          degree_smoother, delta_t )
  end select
  
  SLL_ALLOCATE(efield(kernel_smoother_0%n_dofs,2),ierr)
  SLL_ALLOCATE(bfield(kernel_smoother_0%n_dofs),ierr)
  SLL_ALLOCATE(efield_ref(kernel_smoother_0%n_dofs,2),ierr)
  SLL_ALLOCATE(bfield_ref(kernel_smoother_0%n_dofs),ierr)
  SLL_ALLOCATE(rho(kernel_smoother_0%n_dofs),ierr)
  SLL_ALLOCATE(rho_local(kernel_smoother_0%n_dofs),ierr)
  efield(:,1)=1.0_f64
  efield(:,2) = [0.1_f64, 0.5_f64, 0.3_f64, 0.4_f64, 0.6_f64, &
       0.4_f64, 0.1_f64, 0.7_f64, 0.0_f64, 0.3_f64 ]

  rho_local = 0.0_f64
  do i_part = 1,n_particles
     xi = particle_group%group(i_sp)%get_x(i_part)
     wi(1) = particle_group%group(i_sp)%get_charge( i_part)
     call kernel_smoother_0%add_charge(xi(1), wi(1), rho_local)
  end do
  ! MPI to sum up contributions from each processor
  rho = 0.0_f64
  call sll_o_collective_allreduce( sll_v_world_collective, &
       rho_local, &
       kernel_smoother_0%n_dofs, MPI_SUM, rho)
  ! Solve Poisson problem
  call maxwell_solver%compute_E_from_rho( rho, efield(:,1))
  bfield = [0.5_f64, 0.2_f64, 0.3_f64, 0.5_f64, 0.4_f64, &
       0.5_f64, 1.0_f64, 0.5_f64, 0.4_f64, 0.5_f64]

  call propagator%init( kernel_smoother_0, kernel_smoother_1, &
       particle_group, efield, bfield, &
       eta_min, eta_max-eta_min, solver_tolerance)
  
   call propagator%advect_x( delta_t )

  ! Compare to reference
  ! Particle information after advect_x application 
  particle_info_check(:,1) = [11.627560396526469_f64,  5.513518212243155_f64]
  particle_info_check(:,2) = [-1.534120544352545_f64,  0.157310684610170_f64]
  particle_info_check(:,3) = [ 0.157310684610170_f64, -1.534120544352545_f64]
  particle_info_check(:,4) = [ 6.863675937607472_f64,  5.702694676751700_f64]
  ! Compare computed values to reference values
  do i_part=1,n_particles
     xi = particle_group%group(i_sp)%get_x(i_part)
     if (abs(xi(1)-particle_info_check(i_part,1))> EQV_TOL) then
        passed = .FALSE.
     end if
     xi = particle_group%group(i_sp)%get_v(i_part)
     if (abs(xi(1)-particle_info_check(i_part,2))> EQV_TOL) then
        passed = .FALSE.
     elseif (abs(xi(2)-particle_info_check(i_part,3))> EQV_TOL) then
        passed = .FALSE.
     end if
     xi(1:1) = particle_group%group(i_sp)%get_charge(i_part)
     if (abs(xi(1)-particle_info_check(i_part,4))> EQV_TOL) then
        passed = .FALSE.
     end if
  end do
  
  if (passed .EQV. .FALSE.) then
     print*, 'Error in advect_x.'
  end if

  ! Reset particle info
  ! Initialize particles from particle_info_ref
  xi = 0.0_f64
  do i_part =1, n_particles
     xi(1) = particle_info_ref(i_part, 1) 
     call particle_group%group(i_sp)%set_x(i_part, xi)
     xi(1:2) = particle_info_ref(i_part, 2:3)
     call particle_group%group(i_sp)%set_v(i_part, xi)
     xi(1) = particle_info_ref(i_part, 4)
     call particle_group%group(i_sp)%set_weights(i_part, xi(1))
  end do

  call propagator%advect_eb( delta_t )

  ! Compare to reference
  efield_ref = reshape([ 8.23414233055657E-002_f64,  0.325897972624055_f64, &
      -3.354087313020451_f64,        1.080866372592735_f64, &
       2.341947957403661_f64,       -0.487219147411402_f64, &
      -0.148189210969253_f64,       -4.242900111791700_f64, &
       1.344423272480776_f64,        3.056918784786012_f64, &
       0.139102302186294_f64,        0.481962592465883_f64, &
       0.285041351835316_f64,        0.408878334275259_f64, &
       0.600352549621845_f64,        0.335318939734047_f64, &
       0.169109587509381_f64,        0.689349927342732_f64, &
       2.309088347490475E-003_f64,   0.288575326681749_f64], [num_cells,2])

  error = maxval(efield-efield_ref)
  if (error> EQV_TOL) then
     passed = .FALSE.
     print*, 'e field wrong in advect_eb.', error
  end if

  bfield_ref = [ 0.513905089831431_f64,       0.17044252819383_f64, &
       0.315792994366130_f64,       0.491093809449477_f64, &
       0.384423735883642_f64,       0.518503099429377_f64, &
       1.018549880730556_f64,       0.455427053116144_f64, &
       0.455188601449105_f64,       0.476673207550302_f64]

  error = maxval(bfield-bfield_ref)
  if (error> EQV_TOL) then
     passed = .FALSE.
     print*, 'b field wrong in advect_eb.', error
  end if

  
  call propagator%advect_ev( delta_t )
  ! Compare to reference
  efield_ref = reshape([  0.314556852862353_f64,       0.2172674745439_f64,&
      -3.284664748545794_f64,        0.945737637652102_f64,&
       2.412289173852416_f64,       -0.558336478357940_f64, &
      -2.092024459004936E-002_f64,  -4.551892287906361_f64, &
       2.757177458595688_f64,        2.519072548199334_f64, &
       0.429325658242369_f64,       -7.999157272304736E-002_f64, &
       1.245429130306090_f64,        0.606333225327757_f64, &
       0.441822158903339_f64,        0.382744189118006_f64, &
       0.228340574299206_f64,        0.514300155705115_f64, &
       3.949454751553475E-002_f64,   0.161267676700618_f64], [num_cells,2])

  error = maxval(efield-efield_ref)
  if (error> EQV_TOL) then
     passed = .FALSE.
     print*, 'e field wrong in advect_ev.', error
  end if

  ! Particle information after advect_ev application 
  particle_info_check(:,1) = [11.780972450961723_f64,    5.49778714378213_f64]
  particle_info_check(:,2) = [-1.440260860210953_f64,    0.11596562368166_f64 ]
  particle_info_check(:,3) = [ 0.260321270772527_f64,   -1.4765039843992_f64]
  particle_info_check(:,4) = [ 6.863675937607472_f64,    5.7026946767517_f64]
  ! Compare computed values to reference values
  do i_part=1,n_particles
     xi = particle_group%group(i_sp)%get_x(i_part)
     if (abs(xi(1)-particle_info_check(i_part,1))> EQV_TOL) then
        passed = .FALSE.
     end if

     xi = particle_group%group(i_sp)%get_v(i_part)
     if (abs(xi(1)-particle_info_check(i_part,2))> EQV_TOL) then
        passed = .FALSE.
     elseif (abs(xi(2)-particle_info_check(i_part,3))> EQV_TOL) then
        passed = .FALSE.
     end if
         
     xi(1:1) = particle_group%group(i_sp)%get_charge(i_part)
     if (abs(xi(1)-particle_info_check(i_part,4))> EQV_TOL) then
        passed = .FALSE.
     end if
   end do
 
  if (passed .EQV. .FALSE.) then
     print*, 'Error in advect_ev.'
  end if

  if (passed .EQV. .TRUE.) then
     print*, 'PASSED'
  else
     print*, 'FAILED'
     stop
  end if

  particle_group => null()
  call propagator%free()
  call pg%free()
  deallocate(pg)
  deallocate(efield)
  deallocate(efield_ref)
  deallocate(bfield)
  deallocate(bfield_ref)
  deallocate(rho)
  deallocate(rho_local)
  call kernel_smoother_0%free()
  deallocate(kernel_smoother_0)
  call kernel_smoother_1%free()
  deallocate(kernel_smoother_1)
  call maxwell_solver%free()
  deallocate(maxwell_solver)
  
  call sll_s_halt_collective()

end program test_time_propagator_pic_1d2v_vm_ecsim2o 
