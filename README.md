# Shell-JUnit
Unit test framework for shell script which create junit xml file (for Jenkins/Hudson)

Source the junit.sh in your main script and create a array that include all function

syntax:

```
MY_JUNIT <out_filename> <description> <array>
```

ex:
```
included_spec=( network_test disk_test mem_test cpu_test )

MY_JUNIT junit.xml "Infra-Sanity" ${included_spec[*]} 
```
