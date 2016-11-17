#!/bin/bash

num_groups=2
num_percursor_groups=8
start_column=9
stop_column=$(echo "$(($start_column + ($num_groups - 1) * 2))")
precursor_stop_column=$(echo "$(($start_column + ($num_precursor_groups - 1) * 2))")
gsxs_start_column=7
gsxs_stop_column=$(echo "$(($gsxs_start_column + ($num_groups*$num_groups - 1) * 2))")
chi_start_column=7
chi_stop_column=$(echo "$(($chi_start_column + ($num_groups - 1) * 2))")
root=msr2g_enrU_two_mat_homogenization
# > $fuel_out
# > $mod_out
group_names=""
for i in $(seq $num_groups); do group_names=$group_names"Group"$i" "; done
# echo "var_type temp $group_names" >> $fuel_out
# echo "var_type temp $group_names" >> $mod_out

fuel_temp_start=750
fuel_temp_stop=1000
mod_temp_start=750
mod_temp_stop=1000
fuel_step=50
mod_step=50
fuel_temp_range=($(seq $fuel_temp_start $fuel_step $fuel_temp_stop))
mod_temp_range=($(seq $mod_temp_start $mod_step $mod_temp_stop))

xsecs=(FLUX REMXS FISSXS NUBAR NSF FISSE DIFFCOEF RECIPVEL)
start_cols=()
stop_cols=()
for index in ${!xsecs[@]}; do
    start_cols+=("$start_column")
    stop_cols+=("$stop_column")
done
xsecs+=("CHI")
start_cols+=("$chi_start_column")
stop_cols+=("$chi_stop_column")
xsecs+=("GTRANSFXS")
start_cols+=("$gsxs_start_column")
stop_cols+=("$gsxs_stop_column")
xsecs+=("BETA_EFF" "DECAY_CONSTANT")
start_cols+=("$start_column" "$start_column")
stop_cols+=("$precursor_stop_column" "$precursor_stop_column")

lengths=("${#xsecs[@]}" "${#start_cols[@]}" "${#stop_cols[@]}")
for index in $(seq $((${#lengths[@]} - 1))); do
    if [ "${lengths[$index]}" != "${lengths[0]}" ]; then
        echo "Lengths of xsecs, start_cols, and stop_cols are not all equal" >&2
        exit 1
    fi
done

mkdir interpolation_files
for fuel_temp in ${fuel_temp_range[@]}; do
    echo $fuel_temp
    mod_out=${root}_fuel_${fuel_temp}_mod_interp
    > "interpolation_files/${mod_out}_${xsecs[index]}.txt"
    for index in "${!xsecs[@]}"; do
        for mod_temp in ${mod_temp_range[@]}; do
            # fuel_out=${root}_mod_${mod_temp}_fuel_interp
            # > ${fuel_out}_${xsecs[index]}.txt
            res_file=${root}_fuel_${fuel_temp}_mod_${mod_temp}_res.m
            # awk -v start_column=${start_cols[index]} -v stop_column=${stop_cols[index]} -v fuel_temp=$fuel_temp -v xsec=${xsecs[index]} \
            #     'BEGIN {ORS = ""} $1==xsec {j++} j==1 {print fuel_temp" "; for (i=start_column; i <= stop_column; i=i+2) print $i" "; print "\n"; exit}' $res_file >> ${fuel_out}_${xsecs[index]}.txt
            awk -v start_column=${start_cols[index]} -v stop_column=${stop_cols[index]} -v mod_temp=$mod_temp -v xsec=${xsecs[index]} \
                'BEGIN {ORS = ""} $1==xsec {j++} j==2 {print mod_temp" "; for (i=start_column; i <= stop_column; i=i+2) print $i" "; print "\n"; exit}' $res_file >> "interpolation_files/${mod_out}_${xsecs[index]}.txt"
        done
    done
done

# column -t $fuel_out > tmp
# cat tmp > $fuel_out
# column -t $mod_out > tmp
# cat tmp > $mod_out
# rm tmp