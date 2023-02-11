! Licensed under the Apache License, Version 2.0 (the "License");
! you may not use this file except in compliance with the License.
! You may obtain a copy of the License at
!
!     http://www.apache.org/licenses/LICENSE-2.0
!
! Unless required by applicable law or agreed to in writing, software
! distributed under the License is distributed on an "AS IS" BASIS,
! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
! See the License for the specific language governing permissions and
! limitations under the License.

module var_global
    ! global variabls
    !use mpi

    implicit none

    include 'mpif.h'
    real*8          lname, maxrung, maxcomb, PI
    parameter(lname=150, maxrung=20, maxcomb=10, PI=3.14159265358979d0)
    real*8          stime_FCDI, etime_FCDI, stime_FC, etime_FC, stime_DI, etime_DI
    real*8          decorr_theta, decorr_delta, decorr_alpha
    real*8          fmax_min, fmax_max, bwidth, L1_tole, L1_minrmse, L1_elastic
    integer         nsf, nvf, ntask, vfsize, ndimtype, fcomplexity, rung, fs_size_DI, fs_size_L0
    integer         ptype, L1_max_iter, L1_nlambda, L1_dens, desc_dim, nmodels, CV_fold
    integer         CV_repeat, iFCDI, fileunit, task_weighting, nreaction, npoints, restart
    integer         mpierr, mpirank, mpisize, status(MPI_STATUS_SIZE)
    integer*8       nf_sis(10000), nsis(10000)
    character       vf2sf*10, ops(maxrung)*200, method_so*10, metric*10
    logical         L1_warm_start, L1_weighted, fit_intercept, ffdecorr, scmt
    character(len=lname), allocatable:: pfname(:)

    integer, allocatable    :: nsample(:), ngroup(:, :), isconvex(:, :), react_speciesID(:, :)
    real*8, allocatable     :: prop_y(:), psfeat(:, :), res(:), feature_units(:, :)
    real*8, allocatable     :: pvfeat(:, :, :), react_coeff(:, :)

    logical         use_yunit !WH
    real*8, allocatable     :: target_unit(:) !WH
    
end module
