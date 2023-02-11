FORTRAN = mpiifort -fp-model precise

SISSO: var_global.o libsisso.o FC.o DI.o SISSO.f90
	$(FORTRAN) $^ -o ../$@

%.o: %.f90
	$(FORTRAN) -c $<
