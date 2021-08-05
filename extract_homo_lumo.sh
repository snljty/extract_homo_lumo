#! /bin/bash

# This script extracts energies of HOMO and LUMO of restricted or unrestricted methods, 
# or SOMOs of Restricted-open method, of program Gaussian or ORCA.

if [[ -n "$3" ]]
then
    echo 'Error! At most 2 command argument is required!' 1>&2
    echo 'Exiting abnormally.' 1>&2
    exit 1
fi
if [[ -z "$1" ]]
then
    echo 'Input the name of the Gaussian/ORCA SP task output file:' 1>&2
    read ifl_name
else
    if [ $1 = "-h" -o $1 = "--help" -o $1 = "/?" ]
    then
        echo "Usage: $0 [input] [output]" 1>&2
        echo 1>&2
        echo 'This script extracts energies of HOMO and LUMO of restricted or unrestricted methods,' 1>&2
        echo 'or SOMOs of Restricted-open method, of program Gaussian or ORCA.' 1>&2
        echo 1>&2
        echo 'Exiting normally.' 1>&2
        exit
    else
        ifl_name=$1
    fi
fi
if [[ ! -r ${ifl_name} ]]
then
    echo "Error! Cannot open \"${ifl_name}\" for reading!" 1>&2
    echo 'Exiting abnormally.' 1>&2
    exit 1
fi
if [[ -n "$2" ]]
then
    ofl_name=$2
fi
if [[ -e ${ofl_name} ]]
then
    echo "Warning: File \"${ofl_name}\" already exists, will print to stdout instead."
    unset ofl_name
fi

if [[ -n `grep -m 1 -o 'O   R   C   A' ${ifl_name}` ]]
then
    software=ORCA
    if [[ -n "`grep -A 2 'ORBITAL ENERGIES' ${ifl_name} | tail -n 1 | tr -d '\r'`" ]]
    then
        wfntype='Unrestricted'
    else
        nline=`grep -n 'ORBITAL ENERGIES' ${ifl_name} | awk -F ':' '{print int($1)'}`
        nline=$((${nline}+4))
        while [[ `head -n ${nline} ${ifl_name} | tail -n 1 | awk '{print $2}'` = '2.0000' ]]
        do
            nline=$((${nline}+1))
        done
        if [[ `head -n ${nline} ${ifl_name} | tail -n 1 | awk '{print $2}'` = '1.0000' ]]
        then
            wfntype='Restricted Open'
        elif [[ `head -n ${nline} ${ifl_name} | tail -n 1 | awk '{print $2}'` = '0.0000' ]]
        then
            wfntype='Restricted'
        else
            echo 'Error! This is not recongnized as a restricted, unrestricted or restricted-open wavefunction!' 1>&2
            echo 'Exiting abnormally.' 1>&2
            unset nline
            exit 1
        fi
        unset nline
    fi
elif [[ -n `grep -m 1 -o 'Gaussian(R)' ${ifl_name}` ]]
then
    software=Gaussian
    if [[ -n `grep -m 1 -o 'Beta virt' ${ifl_name}` ]]
    then
        wfntype='Unrestricted'
    elif [[ -n `grep -m 1 -o 'Alpha virt' ${ifl_name}` ]]
    then
        multiplicity=`grep 'Multiplicity =' ${ifl_name} | awk -F 'Multiplicity =' '{print int($2)}'`
        if [[ -z ${multiplicity} ]]
        then
            echo "Error! Cannot get the multiplicity!" 1>&2
            echo "Exiting abnormally." 1>&2
            exit 1
        fi
        if [[ ${multiplicity} -gt 1 ]]
        then
            wfntype='Restricted Open'
        else
            wfntype='Restricted'
        fi
    else
        echo 'Error! This is not recongnized as a restricted, unrestricted or restricted-open wavefunction!' 1>&2
        echo 'Exiting abnormally.' 1>&2
        exit 1
    fi
else
    echo 'Error! This is neither a Gaussian output file nor an ORCA output file!' 1>&2
    echo 'Exiting abnormally.' 1>&2
    exit 1
fi

echo "Software is \"${software}\"." 1>&2
echo "Wavefunctions type is \"${wfntype}\"." 1>&2

case ${wfntype} in
    'Restricted' )
    echo 'Note: The first line is HOMO, the second line is LUMO.' 1>&2
    case ${software} in
        'Gaussian' )
        homo="`grep 'Alpha  occ. eigenvalues' ${ifl_name} | tail -n 1 | \
            awk '{printf "%9.4f\n", 27.2114*$NF}'`"
        lumo="`grep 'Alpha virt. eigenvalues' ${ifl_name} | head -n 1 | \
            awk -F '--' '{printf "%9.4f\n", 27.2114*$2}'`"
        ;;
        'ORCA' )
        nline=`grep -n 'ORBITAL ENERGIES' ${ifl_name} | awk -F ':' '{print int($1)'}`
        nline=$((${nline}+4))
        while [[ `head -n ${nline} ${ifl_name} | tail -n 1 | awk '{print $2}'` = '2.0000' ]]
        do
            nline=$((${nline}+1))
        done
        lumo="`head -n ${nline} ${ifl_name} | tail -n 1 | awk '{printf "%9.4f\n", $4}'`"
        nline=$((${nline}-1))
        homo="`head -n ${nline} ${ifl_name} | tail -n 1 | awk '{printf "%9.4f\n", $4}'`"
        unset nline
        ;;
        * )
        echo 'This method is not applied yet.'
        exit 2
        ;;
    esac
    if [[ -z "${ofl_name}" ]]
    then
        echo "${homo}"
        echo "${lumo}"
    else
        echo "${homo}" 1>${ofl_name}
        echo "${lumo}" 1>${ofl_name}
    fi
    unset homo
    unset lumo
    ;;
    'Unrestricted' )
    echo 'Note: The first line is HOMO, the second line is LUMO.' 1>&2
    echo 'Note: Alpha spin on left, beta spin on right.' 1>&2
    case ${software} in
        'Gaussian' )
        ahomo="`grep 'Alpha  occ. eigenvalues' ${ifl_name} | tail -n 1 | \
            awk '{printf "%9.4f\n", 27.2114*$NF}'`"
        alumo="`grep 'Alpha virt. eigenvalues' ${ifl_name} | head -n 1 | \
            awk -F '--' '{printf "%9.4f\n", 27.2114*$2}'`"
        bhomo="`grep 'Beta  occ. eigenvalues' ${ifl_name} | tail -n 1 | \
            awk '{printf "%9.4f\n", 27.2114*$NF}'`"
        blumo="`grep 'Beta virt. eigenvalues' ${ifl_name} | head -n 1 | \
            awk -F '--' '{printf "%9.4f\n", 27.2114*$2}'`"
        ;;
        'ORCA' )
        nline=`grep -n 'SPIN UP ORBITALS' ${ifl_name} | awk -F ':' '{print int($1)'}`
        nline=$((${nline}+2))
        while [[ `head -n ${nline} ${ifl_name} | tail -n 1 | awk '{print $2}'` = '1.0000' ]]
        do
            nline=$((${nline}+1))
        done
        alumo="`head -n ${nline} ${ifl_name} | tail -n 1 | awk '{printf "%9.4f\n", $4}'`"
        nline=$((${nline}-1))
        ahomo="`head -n ${nline} ${ifl_name} | tail -n 1 | awk '{printf "%9.4f\n", $4}'`"
        nline=`grep -n 'SPIN DOWN ORBITALS' ${ifl_name} | awk -F ':' '{print int($1)'}`
        nline=$((${nline}+2))
        while [[ `head -n ${nline} ${ifl_name} | tail -n 1 | awk '{print $2}'` = '1.0000' ]]
        do
            nline=$((${nline}+1))
        done
        blumo="`head -n ${nline} ${ifl_name} | tail -n 1 | awk '{printf "%9.4f\n", $4}'`"
        nline=$((${nline}-1))
        bhomo="`head -n ${nline} ${ifl_name} | tail -n 1 | awk '{printf "%9.4f\n", $4}'`"
        unset nline
        ;;
        * )
        echo 'This method is not applied yet.'
        exit 2
        ;;
    esac
    if [[ -z "${ofl_name}" ]]
    then
        echo "${ahomo}        ${bhomo}"
        echo "${alumo}        ${blumo}"
    else
        echo "${ahomo}        ${bhomo}" 1>${ofl_name}
        echo "${alumo}        ${blumo}" 1>${ofl_name}
    fi
    unset ahomo
    unset alumo
    unset bhomo
    unset blumo
    ;;
    'Restricted Open' )
    echo "Warning: only SOMOs will be printed for ${wfntype} method." 1>&2
    case ${software} in
        'Gaussian' )
        somo=`grep 'Alpha  occ. eigenvalues' ${ifl_name} | awk -F '--' '{print $2}' | \
            sed 's/ \+/\n/g' | grep -v ^$ | tail -n $((${multiplicity}-1)) | \
            awk '{printf "%9.4f\n", 27.2114*$1}'`
        unset multiplicity
        ;;
        'ORCA' )
        nline=`grep -n 'ORBITAL ENERGIES' ${ifl_name} | awk -F ':' '{print int($1)'}`
        nline=$((${nline}+4))
        while [[ `head -n ${nline} ${ifl_name} | tail -n 1 | awk '{print $2}'` = '2.0000' ]]
        do
            nline=$((${nline}+1))
        done
        nlinebeg=${nline}
        while [[ `head -n ${nline} ${ifl_name} | tail -n 1 | awk '{print $2}'` = '1.0000' ]]
        do
            nline=$((${nline}+1))
        done
        nlineend=$((${nline}-1))
        somo=`head -n ${nlineend} ${ifl_name} | tail -n +${nlinebeg} | awk '{printf "%9.4f\n", $4}'`
        unset nline
        unset nlinebeg
        unset nlineend
        ;;
        * )
        echo 'This method is not applied yet.'
        exit 2
        ;;
    esac
    if [[ -z ${ofl_name} ]]
    then
        echo "${somo}"
    else
        echo "${somo}" 1>${ofl_name}
    fi
    unset somo
    ;;
    * )
    echo 'This method is not applied yet.'
    exit 2
    ;;
esac
echo 'Note: orbital energy is in unit eV.' 1>&2

unset wfntype
unset software

echo 1>&2
echo 'Exiting normally.' 1>&2

