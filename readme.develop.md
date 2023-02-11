# Log for developing SISSO through docker

## Setting up the environment

### Docker environment

Docker image can be obtained from the intel: [Using-containers](https://www.intel.com/content/www/us/en/develop/documentation/get-started-with-intel-oneapi-hpc-linux/top/using-containers.html). After obtaining the image. We can start the docker container using:

```bash
docker run -it --name sisso -v "$(pwd)":/SISSO -w /SISSO --rm intel/oneapi-hpckit
```

This creates an container that shared the folder with the host. The current folder (`SISSOcode`) will be available in docker as `/SISSO`. All changes made on either side will be visible in real time. `--rm` option will clean up the container after finishing. `-w` option set the working directory.

To make the terminal look nicer, export:

```bash
export PS1="\[\e[1;32m\]Container\[\e[m\]\[\e[1;34m\]:\W\[\e[m\]$ "
```

### Compile

To compile, we can run the following commend:

```bash
mpiifort -fp-model precise var_global.f90 libsisso.f90 DI.f90 FC.f90 SISSO.f90 -o ../SISSO
```

Using the following makefile make development faster:

```makefile
FORTRAN = mpiifort -fp-model precise

SISSO: var_global.o libsisso.o FC.o DI.o SISSO.f90
    $(FORTRAN) $^ -o ../$@

%.o: %.f90
    $(FORTRAN) $<
```

## Related code piece

The code that determine the unit dimension: `SISSO.f90, line 368`:

```fortran
ndimtype = 0
k = 0
do while (index(funit(k + 1:), '(') > 0)
    k = index(funit(k + 1:), '(') + k
    ndimtype = ndimtype + 1
end do
```

The actual feature units are stored in variable `feature_units(ndim, nfeature)` and is determined by `SISSO.f90 line 496:

```fortran
feature_units = 0.d0   ! dimensionless for default
do ll = 1, ndimtype
    i = index(funit, '(')
    j = index(funit, ':')
    kk = index(funit, ')')
    if (i > 0 .and. j > 0) then
        read (funit(i + 1:j - 1), *, err=1001) k
        read (funit(j + 1:kk - 1), *, err=1001) l
        feature_units(ll, k:l) = 1.d0
        funit(:kk) = ''
    end if
end do

inquire (file='feature_units', exist=fexist)
if (fexist) then
    open (1, file='feature_units', status='old')
    do i = 1, nsf + nvf
        read (1, *) feature_units(:, i)
    end do
    close (1)
end if
```

### Subroutine and functions in FC.f90

The following are a list of functions:

```fortran
subroutine feature_construction
     ! the main subroutine provided
subroutine combine(
    fin1, name_in1, lastop_in1, compl_in1, dim_in1, 
    fin2, name_in2, lastop_in2, compl_in2, dim_in2, op, nf)
subroutine addm_out(n)
    ! increase array size of `fout`, `name_out`, `lastop_out`
    ! `complexity_out` and `dim_out`
subroutine addm_in1(
    n, fin1, name_in1, lastop_in1, complexity_in1, dim_in1)
    ! increase size of the input array (last dimension) by n
subroutine addm_vf(n)
    ! increase array size of the `vfeat` dimension by n
    ! by first copying the vfeat to an array and then deallocate 
    ! vfeat, followed by allocating additional size for vfeat
subroutine writeout(phiname, i, j, k)
    ! simply write "Total number of features in the space {k}"
    ! Total number of features in the space phi01:             15
subroutine update_availability(available, pavailable)
    ! not so sure
subroutine dup_pcheck(
    nfpcore_this, fidentity, fname, complexity, order, available, ftype)
subroutine sure_indep_screening(
    nfpcore_this, available, complexity, fname, 
    feat, sisfeat, name_sisfeat)
subroutine dup_scheck(
    nf, fidentity, fname, complexity, order, available, ftype)
subroutine isgoodf(feat, name_feat, lastop, compl, dimens, nf)
    ! call goodf() and update `nf`, `fout`, `name_out`, 
    ! `lastop_out`, `complexity_out` and `dim_out`
subroutine isgoodvf(feat, name_feat, lastop, compl, dimens, nf)
    ! convert vector feature to scalar value and apply goodf()
subroutine update_select

function goodf(feat, name_feat, dimens, compl)
    ! check feature, does two things:
    ! 1. return true or false
    ! 2. if not returned early, put in *_select list
function dimcomb(dim1, dim2, op)
    ! calculate the new unit according to the operation
function simpler(complexity1, complexity2, name1, name2)
    ! uniquely determine which one has lower complexity, if equal 
    ! complexity, compare the length of the name
    ! return integer 1 or 2
function sis_score(feat, yyy)
    ! correlation between a feature feat and the property yyy
    ! return a tuple of two values
    ! only the first value is related to regression
function isscalar(fname)
    ! give a feature name, return true if it is a vector feature
function ffcorr(feat1, feat2)
    ! correlationship coefficients
function equivalent(score1, score2, feat1, feat2)
    ! return true if score1 == score2 or corr(feat1, feat2) == 1
    
```

The `rung` parameter is calculated from feature compexity, which is the number of operations that generated the feature. combination are called `rung` times during feature selection:

```fortran
if (fcomplexity == 0) then
    rung = 0
elseif (fcomplexity == 1) then
    rung = 1
elseif (fcomplexity > 1 .and. fcomplexity <= 3) then
    rung = 2
elseif (fcomplexity > 3 .and. fcomplexity <= 7) then
    rung = 3
elseif (fcomplexity > 7 .and. fcomplexity <= 15) then
    rung = 4
end if
```

## Strategy to modify the code

### additional parameters

We use a single additional parameters to indicate if the target unit should be considered: `logical : use_yunit` and an allocatable parameter `target_unit`.

If `use_yunit`, we can check inside the function `goodf()`:

```fortran
if (ptype == 1 .and. use_yunit) then
    ! not to be selected but can be used for further transformations, WH
    if (maxval(abs(target_unit - dimens)) > 1d-8) return
end if 
```

In feature_construction, the feature_in and feature_out are only the temperary values that are passed in feature selection stage. The selected features are only incremented in the `goodf()` function.