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

## Strategy to modify the code

### additional parameters

We use a single additional parameters to indicate if the target unit should be considered: `logical : target_unit`