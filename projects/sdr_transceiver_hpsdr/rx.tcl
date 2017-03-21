# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_0 {
  DIN_WIDTH 8 DIN_FROM 0 DIN_TO 0 DOUT_WIDTH 1
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_5 {
  DIN_WIDTH 160 DIN_FROM 15 DIN_TO 0 DOUT_WIDTH 16
}

# Create axis_clock_converter
cell xilinx.com:ip:axis_clock_converter:1.1 fifo_0 {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 8
} {
  m_axis_aclk /ps_0/FCLK_CLK0
  m_axis_aresetn /rst_0/peripheral_aresetn
}

# Create axis_broadcaster
cell xilinx.com:ip:axis_broadcaster:1.1 bcast_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 8
  M_TDATA_NUM_BYTES 2
  NUM_MI 4
  M00_TDATA_REMAP {tdata[15:0]}
  M01_TDATA_REMAP {tdata[31:16]}
  M02_TDATA_REMAP {tdata[31:16]}
  M03_TDATA_REMAP {tdata[47:32]}
} {
  S_AXIS fifo_0/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

for {set i 0} {$i <= 3} {incr i} {

  # Create xlslice
  cell xilinx.com:ip:xlslice:1.0 slice_[expr $i + 1] {
    DIN_WIDTH 8 DIN_FROM $i DIN_TO $i DOUT_WIDTH 1
  }

  # Create xlslice
  cell xilinx.com:ip:xlslice:1.0 slice_[expr $i + 6] {
    DIN_WIDTH 160 DIN_FROM [expr 32 * $i + 63] DIN_TO [expr 32 * $i + 32] DOUT_WIDTH 32
  }

  # Create axis_constant
  cell pavel-demin:user:axis_constant:1.0 phase_$i {
    AXIS_TDATA_WIDTH 32
  } {
    cfg_data slice_[expr $i + 6]/Dout
    aclk /ps_0/FCLK_CLK0
  }

  # Create dds_compiler
  cell xilinx.com:ip:dds_compiler:6.0 dds_$i {
    DDS_CLOCK_RATE 125
    SPURIOUS_FREE_DYNAMIC_RANGE 138
    FREQUENCY_RESOLUTION 0.2
    PHASE_INCREMENT Streaming
    HAS_TREADY true
    HAS_ARESETN true
    HAS_PHASE_OUT false
    PHASE_WIDTH 30
    OUTPUT_WIDTH 24
    DSP48_USE Minimal
    NEGATIVE_SINE true
  } {
    S_AXIS_PHASE phase_$i/M_AXIS
    aclk /ps_0/FCLK_CLK0
    aresetn slice_[expr $i + 1]/Dout
  }

  # Create axis_lfsr
  cell pavel-demin:user:axis_lfsr:1.0 lfsr_$i {} {
    aclk /ps_0/FCLK_CLK0
    aresetn /rst_0/peripheral_aresetn
  }

  # Create cmpy
  cell xilinx.com:ip:cmpy:6.0 mult_$i {
    FLOWCONTROL Blocking
    APORTWIDTH.VALUE_SRC USER
    BPORTWIDTH.VALUE_SRC USER
    APORTWIDTH 14
    BPORTWIDTH 24
    ROUNDMODE Random_Rounding
    OUTPUTWIDTH 26
  } {
    S_AXIS_A bcast_0/M0${i}_AXIS
    S_AXIS_B dds_$i/M_AXIS_DATA
    S_AXIS_CTRL lfsr_$i/M_AXIS
    aclk /ps_0/FCLK_CLK0
  }

  # Create axis_broadcaster
  cell xilinx.com:ip:axis_broadcaster:1.1 bcast_[expr $i + 1] {
    S_TDATA_NUM_BYTES.VALUE_SRC USER
    M_TDATA_NUM_BYTES.VALUE_SRC USER
    S_TDATA_NUM_BYTES 8
    M_TDATA_NUM_BYTES 3
    M00_TDATA_REMAP {tdata[23:0]}
    M01_TDATA_REMAP {tdata[55:32]}
  } {
    S_AXIS mult_$i/M_AXIS_DOUT
    aclk /ps_0/FCLK_CLK0
    aresetn /rst_0/peripheral_aresetn
  }

}

for {set i 0} {$i <= 7} {incr i} {

  # Create axis_variable
  cell pavel-demin:user:axis_variable:1.0 rate_$i {
    AXIS_TDATA_WIDTH 16
  } {
    cfg_data slice_5/Dout
    aclk /ps_0/FCLK_CLK0
    aresetn /rst_0/peripheral_aresetn
  }

  # Create cic_compiler
  cell xilinx.com:ip:cic_compiler:4.0 cic_$i {
    INPUT_DATA_WIDTH.VALUE_SRC USER
    FILTER_TYPE Decimation
    NUMBER_OF_STAGES 6
    SAMPLE_RATE_CHANGES Programmable
    MINIMUM_RATE 125
    MAXIMUM_RATE 8192
    FIXED_OR_INITIAL_RATE 500
    INPUT_SAMPLE_FREQUENCY 125
    CLOCK_FREQUENCY 125
    INPUT_DATA_WIDTH 24
    QUANTIZATION Truncation
    OUTPUT_DATA_WIDTH 24
    USE_XTREME_DSP_SLICE false
    HAS_DOUT_TREADY true
    HAS_ARESETN true
  } {
    S_AXIS_DATA bcast_[expr $i / 2 + 1]/M0[expr $i % 2]_AXIS
    S_AXIS_CONFIG rate_$i/M_AXIS
    aclk /ps_0/FCLK_CLK0
    aresetn /rst_0/peripheral_aresetn
  }

}

# Create axis_combiner
cell  xilinx.com:ip:axis_combiner:1.1 comb_0 {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 3
  NUM_SI 8
} {
  S00_AXIS cic_0/M_AXIS_DATA
  S01_AXIS cic_1/M_AXIS_DATA
  S02_AXIS cic_2/M_AXIS_DATA
  S03_AXIS cic_3/M_AXIS_DATA
  S04_AXIS cic_4/M_AXIS_DATA
  S05_AXIS cic_5/M_AXIS_DATA
  S06_AXIS cic_6/M_AXIS_DATA
  S07_AXIS cic_7/M_AXIS_DATA
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter:1.1 conv_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 24
  M_TDATA_NUM_BYTES 3
} {
  S_AXIS comb_0/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create fir_compiler
cell xilinx.com:ip:fir_compiler:7.2 fir_0 {
  DATA_WIDTH.VALUE_SRC USER
  DATA_WIDTH 24
  COEFFICIENTVECTOR {1.1961249863e-08, 1.2656113242e-08, 1.3309358908e-08, 1.3941034466e-08, 1.4577284871e-08, 1.5250466447e-08, 1.5999126380e-08, 1.6867833605e-08, 1.7906848440e-08, 1.9171620108e-08, 2.0722103492e-08, 2.2621888930e-08, 2.4937141679e-08, 2.7735350818e-08, 3.1083890736e-08, 3.5048401979e-08, 3.9691002072e-08, 4.5068340863e-08, 5.1229519040e-08, 5.8213892520e-08, 6.6048789471e-08, 7.4747170707e-08, 8.4305267918e-08, 9.4700237761e-08, 1.0588787301e-07, 1.1780041475e-07, 1.3034451197e-07, 1.4339937649e-07, 1.5681518263e-07, 1.7041176103e-07, 1.8397763614e-07, 1.9726945559e-07, 2.1001185770e-07, 2.2189782077e-07, 2.3258953374e-07, 2.4171982374e-07, 2.4889416998e-07, 2.5369332733e-07, 2.5567657596e-07, 2.5438560470e-07, 2.4934902788e-07, 2.4008752517e-07, 2.2611958469e-07, 2.0696781862e-07, 1.8216581031e-07, 1.5126544051e-07, 1.1384462961e-07, 6.9515421839e-08, 1.7932326771e-08, -4.1199176753e-08, -1.0811407849e-07, -1.8297932947e-07, -2.6588551026e-07, -3.5683880180e-07, -4.5575339146e-07, -5.6244445003e-07, -6.7662181787e-07, -7.9788453816e-07, -9.2571637381e-07, -1.0594824405e-06, -1.1984270824e-06, -1.3416731099e-06, -1.4882225061e-06, -1.6369586998e-06, -1.7866504848e-06, -1.9359576509e-06, -2.0834383713e-06, -2.2275583733e-06, -2.3667018929e-06, -2.4991843954e-06, -2.6232670130e-06, -2.7371726299e-06, -2.8391035153e-06, -2.9272603793e-06, -2.9998626976e-06, -3.0551701281e-06, -3.0915048107e-06, -3.1072743236e-06, -3.1009950394e-06, -3.0713156082e-06, -3.0170402731e-06, -2.9371517077e-06, -2.8308330538e-06, -2.6974888247e-06, -2.5367643381e-06, -2.3485633372e-06, -2.1330634646e-06, -1.8907292580e-06, -1.6223223537e-06, -1.3289085964e-06, -1.0118617792e-06, -6.7286376522e-07, -3.1390077269e-07, 6.2744355816e-08, 4.5450403794e-07, 8.5854208223e-07, 1.2717741070e-06, 1.6908922361e-06, 2.1123940033e-06, 2.5326153400e-06, 2.9477674568e-06, 3.3539773725e-06, 3.7473317769e-06, 4.1239238569e-06, 4.4799026514e-06, 4.8115244440e-06, 5.1152056481e-06, 5.3875765849e-06, 5.6255355116e-06, 5.8263022146e-06, 5.9874704478e-06, 6.1070584697e-06, 6.1835569145e-06, 6.2159732223e-06, 6.2038718500e-06, 6.1474094983e-06, 6.0473646055e-06, 5.9051603899e-06, 5.7228807660e-06, 5.5032785074e-06, 5.2497750941e-06, 4.9664517572e-06, 4.6580313120e-06, 4.3298504706e-06, 3.9878224217e-06, 3.6383895800e-06, 3.2884665245e-06, 2.9453732684e-06, 2.6167591349e-06, 2.3105176459e-06, 2.0346929637e-06, 1.7973785676e-06, 1.6066089745e-06, 1.4702454549e-06, 1.3958568136e-06, 1.3905964346e-06, 1.4610768981e-06, 1.6132435831e-06, 1.8522487606e-06, 2.1823277608e-06, 2.6066788603e-06, 3.1273485830e-06, 3.7451241349e-06, 4.4594347041e-06, 5.2682633429e-06, 6.1680711188e-06, 7.1537351635e-06, 8.2185021735e-06, 9.3539588131e-06, 1.0550020349e-05, 1.1794938703e-05, 1.3075330929e-05, 1.4376228960e-05, 1.5681151229e-05, 1.6972196563e-05, 1.8230160516e-05, 1.9434674022e-05, 2.0564364005e-05, 2.1597035305e-05, 2.2509872977e-05, 2.3279663760e-05, 2.3883035203e-05, 2.4296710670e-05, 2.4497778154e-05, 2.4463970577e-05, 2.4173954994e-05, 2.3607627882e-05, 2.2746413501e-05, 2.1573562086e-05, 2.0074444524e-05, 1.8236839983e-05, 1.6051212914e-05, 1.3510975758e-05, 1.0612733686e-05, 7.3565077152e-06, 3.7459326243e-06, -2.1157381935e-07, -4.5046736336e-06, -9.1180065209e-06, -1.4032125765e-05, -1.9223474710e-05, -2.4664406079e-05, -3.0323245996e-05, -3.6164404192e-05, -4.2148531408e-05, -4.8232724519e-05, -5.4370779428e-05, -6.0513491209e-05, -6.6609000452e-05, -7.2603184194e-05, -7.8440089244e-05, -8.4062405141e-05, -8.9411973420e-05, -9.4430329303e-05, -9.9059271400e-05, -1.0324145449e-04, -1.0692099996e-04, -1.1004411813e-04, -1.1255973607e-04, -1.1442012455e-04, -1.1558151707e-04, -1.1600471401e-04, -1.1565566460e-04, -1.1450601950e-04, -1.1253364661e-04, -1.0972310293e-04, -1.0606605545e-04, -1.0156164422e-04, -9.6216781265e-05, -9.0046379131e-05, -8.3073503774e-05, -7.5329446693e-05, -6.6853712149e-05, -5.7693915960e-05, -4.7905593178e-05, -3.7551912876e-05, -2.6703299179e-05, -1.5436958696e-05, -3.8363155200e-06, 8.0096439618e-06, 2.0007113125e-05, 3.2058289607e-05, 4.4062276739e-05, 5.5916055311e-05, 6.7515518031e-05, 7.8756558001e-05, 8.9536201588e-05, 9.9753775155e-05, 1.0931209429e-04, 1.1811866343e-04, 1.2608687319e-04, 1.3313718199e-04, 1.3919826855e-04, 1.4420814098e-04, 1.4811518866e-04, 1.5087916265e-04, 1.5247207066e-04, 1.5287897311e-04, 1.5209866690e-04, 1.5014424456e-04, 1.4704351683e-04, 1.4283928797e-04, 1.3758947409e-04, 1.3136705595e-04, 1.2425985922e-04, 1.1637015654e-04, 1.0781408765e-04, 9.8720895165e-05, 8.9231975840e-05, 7.9499748934e-05, 6.9686345180e-05, 5.9962122071e-05, 5.0504013152e-05, 4.1493721099e-05, 3.3115766424e-05, 2.5555405684e-05, 1.8996435016e-05, 1.3618896743e-05, 9.5967085478e-06, 7.0952364049e-06, 6.2688339697e-06, 7.2583724812e-06, 1.0188786407e-05, 1.5166661028e-05, 2.2277888902e-05, 3.1585422675e-05, 4.3127151932e-05, 5.6913931836e-05, 7.2927790966e-05, 9.1120345272e-05, 1.1141144420e-04, 1.3368807394e-04, 1.5780354126e-04, 1.8357695995e-04, 2.1079305951e-04, 2.3920233403e-04, 2.6852154618e-04, 2.9843459894e-04, 3.2859378451e-04, 3.5862141681e-04, 3.8811185051e-04, 4.1663388634e-04, 4.4373355840e-04, 4.6893729598e-04, 4.9175544814e-04, 5.1168615591e-04, 5.2821955296e-04, 5.4084227183e-04, 5.4904222921e-04, 5.5231366012e-04, 5.5016236740e-04, 5.4211114982e-04, 5.2770536879e-04, 5.0651861114e-04, 4.7815840291e-04, 4.4227192668e-04, 3.9855169348e-04, 3.4674111860e-04, 2.8663994967e-04, 2.1810949466e-04, 1.4107759738e-04, 5.5543308130e-05, -3.8418802029e-05, -1.4065473376e-04, -2.5092760749e-04, -3.6891471354e-04, -4.9420510855e-04, -6.2629779903e-04, -7.6460054973e-04, -9.0842935040e-04, -1.0570085703e-03, -1.2094718251e-03, -1.3648635759e-03, -1.5221414746e-03, -1.6801794646e-03, -1.8377716396e-03, -1.9936368570e-03, -2.1464240976e-03, -2.2947185558e-03, -2.4370484378e-03, -2.5718924414e-03, -2.6976878815e-03, -2.8128394227e-03, -2.9157283720e-03, -3.0047224798e-03, -3.0781861930e-03, -3.1344912968e-03, -3.1720278797e-03, -3.1892155494e-03, -3.1845148258e-03, -3.1564386330e-03, -3.1035638088e-03, -3.0245425496e-03, -2.9181137071e-03, -2.7831138490e-03, -2.6184880023e-03, -2.4232999904e-03, -2.1967422833e-03, -1.9381452771e-03, -1.6469859243e-03, -1.3228956388e-03, -9.6566740211e-04, -5.7526200496e-04, -1.5181335882e-04, 3.0436717758e-04, 7.9278750903e-04, 1.3127725959e-03, 1.8634633643e-03, 2.4438167652e-03, 3.0526070025e-03, 3.6884279453e-03, 4.3496967289e-03, 5.0346585412e-03, 5.7413925826e-03, 6.4678191796e-03, 7.2117080210e-03, 7.9706874816e-03, 8.7422549845e-03, 9.5237883505e-03, 1.0312558071e-02, 1.1105740435e-02, 1.1900431436e-02, 1.2693661374e-02, 1.3482410066e-02, 1.4263622567e-02, 1.5034225309e-02, 1.5791142555e-02, 1.6531313053e-02, 1.7251706798e-02, 1.7949341779e-02, 1.8621300604e-02, 1.9264746903e-02, 1.9876941379e-02, 2.0455257419e-02, 2.0997196151e-02, 2.1500400838e-02, 2.1962670528e-02, 2.2381972851e-02, 2.2756455881e-02, 2.3084458983e-02, 2.3364522569e-02, 2.3595396690e-02, 2.3776048416e-02, 2.3905667942e-02, 2.3983673382e-02, 2.4009714219e-02, 2.3983673382e-02, 2.3905667942e-02, 2.3776048416e-02, 2.3595396690e-02, 2.3364522569e-02, 2.3084458983e-02, 2.2756455881e-02, 2.2381972851e-02, 2.1962670528e-02, 2.1500400838e-02, 2.0997196151e-02, 2.0455257419e-02, 1.9876941379e-02, 1.9264746903e-02, 1.8621300604e-02, 1.7949341779e-02, 1.7251706798e-02, 1.6531313053e-02, 1.5791142555e-02, 1.5034225309e-02, 1.4263622567e-02, 1.3482410066e-02, 1.2693661374e-02, 1.1900431436e-02, 1.1105740435e-02, 1.0312558071e-02, 9.5237883505e-03, 8.7422549845e-03, 7.9706874816e-03, 7.2117080210e-03, 6.4678191796e-03, 5.7413925826e-03, 5.0346585412e-03, 4.3496967289e-03, 3.6884279453e-03, 3.0526070025e-03, 2.4438167652e-03, 1.8634633643e-03, 1.3127725959e-03, 7.9278750903e-04, 3.0436717758e-04, -1.5181335882e-04, -5.7526200496e-04, -9.6566740211e-04, -1.3228956388e-03, -1.6469859243e-03, -1.9381452771e-03, -2.1967422833e-03, -2.4232999904e-03, -2.6184880023e-03, -2.7831138490e-03, -2.9181137071e-03, -3.0245425496e-03, -3.1035638088e-03, -3.1564386330e-03, -3.1845148258e-03, -3.1892155494e-03, -3.1720278797e-03, -3.1344912968e-03, -3.0781861930e-03, -3.0047224798e-03, -2.9157283720e-03, -2.8128394227e-03, -2.6976878815e-03, -2.5718924414e-03, -2.4370484378e-03, -2.2947185558e-03, -2.1464240976e-03, -1.9936368570e-03, -1.8377716396e-03, -1.6801794646e-03, -1.5221414746e-03, -1.3648635759e-03, -1.2094718251e-03, -1.0570085703e-03, -9.0842935040e-04, -7.6460054973e-04, -6.2629779903e-04, -4.9420510855e-04, -3.6891471354e-04, -2.5092760749e-04, -1.4065473376e-04, -3.8418802029e-05, 5.5543308130e-05, 1.4107759738e-04, 2.1810949466e-04, 2.8663994967e-04, 3.4674111860e-04, 3.9855169348e-04, 4.4227192668e-04, 4.7815840291e-04, 5.0651861114e-04, 5.2770536879e-04, 5.4211114982e-04, 5.5016236740e-04, 5.5231366012e-04, 5.4904222921e-04, 5.4084227183e-04, 5.2821955296e-04, 5.1168615591e-04, 4.9175544814e-04, 4.6893729598e-04, 4.4373355840e-04, 4.1663388634e-04, 3.8811185051e-04, 3.5862141681e-04, 3.2859378451e-04, 2.9843459894e-04, 2.6852154618e-04, 2.3920233403e-04, 2.1079305951e-04, 1.8357695995e-04, 1.5780354126e-04, 1.3368807394e-04, 1.1141144420e-04, 9.1120345272e-05, 7.2927790966e-05, 5.6913931836e-05, 4.3127151932e-05, 3.1585422675e-05, 2.2277888902e-05, 1.5166661028e-05, 1.0188786407e-05, 7.2583724812e-06, 6.2688339697e-06, 7.0952364049e-06, 9.5967085478e-06, 1.3618896743e-05, 1.8996435016e-05, 2.5555405684e-05, 3.3115766424e-05, 4.1493721099e-05, 5.0504013152e-05, 5.9962122071e-05, 6.9686345180e-05, 7.9499748934e-05, 8.9231975840e-05, 9.8720895165e-05, 1.0781408765e-04, 1.1637015654e-04, 1.2425985922e-04, 1.3136705595e-04, 1.3758947409e-04, 1.4283928797e-04, 1.4704351683e-04, 1.5014424456e-04, 1.5209866690e-04, 1.5287897311e-04, 1.5247207066e-04, 1.5087916265e-04, 1.4811518866e-04, 1.4420814098e-04, 1.3919826855e-04, 1.3313718199e-04, 1.2608687319e-04, 1.1811866343e-04, 1.0931209429e-04, 9.9753775155e-05, 8.9536201588e-05, 7.8756558001e-05, 6.7515518031e-05, 5.5916055311e-05, 4.4062276739e-05, 3.2058289607e-05, 2.0007113125e-05, 8.0096439618e-06, -3.8363155200e-06, -1.5436958696e-05, -2.6703299179e-05, -3.7551912876e-05, -4.7905593178e-05, -5.7693915960e-05, -6.6853712149e-05, -7.5329446693e-05, -8.3073503774e-05, -9.0046379131e-05, -9.6216781265e-05, -1.0156164422e-04, -1.0606605545e-04, -1.0972310293e-04, -1.1253364661e-04, -1.1450601950e-04, -1.1565566460e-04, -1.1600471401e-04, -1.1558151707e-04, -1.1442012455e-04, -1.1255973607e-04, -1.1004411813e-04, -1.0692099996e-04, -1.0324145449e-04, -9.9059271400e-05, -9.4430329303e-05, -8.9411973420e-05, -8.4062405141e-05, -7.8440089244e-05, -7.2603184194e-05, -6.6609000452e-05, -6.0513491209e-05, -5.4370779428e-05, -4.8232724519e-05, -4.2148531408e-05, -3.6164404192e-05, -3.0323245996e-05, -2.4664406079e-05, -1.9223474710e-05, -1.4032125765e-05, -9.1180065209e-06, -4.5046736336e-06, -2.1157381935e-07, 3.7459326243e-06, 7.3565077152e-06, 1.0612733686e-05, 1.3510975758e-05, 1.6051212914e-05, 1.8236839983e-05, 2.0074444524e-05, 2.1573562086e-05, 2.2746413501e-05, 2.3607627882e-05, 2.4173954994e-05, 2.4463970577e-05, 2.4497778154e-05, 2.4296710670e-05, 2.3883035203e-05, 2.3279663760e-05, 2.2509872977e-05, 2.1597035305e-05, 2.0564364005e-05, 1.9434674022e-05, 1.8230160516e-05, 1.6972196563e-05, 1.5681151229e-05, 1.4376228960e-05, 1.3075330929e-05, 1.1794938703e-05, 1.0550020349e-05, 9.3539588131e-06, 8.2185021735e-06, 7.1537351635e-06, 6.1680711188e-06, 5.2682633429e-06, 4.4594347041e-06, 3.7451241349e-06, 3.1273485830e-06, 2.6066788603e-06, 2.1823277608e-06, 1.8522487606e-06, 1.6132435831e-06, 1.4610768981e-06, 1.3905964346e-06, 1.3958568136e-06, 1.4702454549e-06, 1.6066089745e-06, 1.7973785676e-06, 2.0346929637e-06, 2.3105176459e-06, 2.6167591349e-06, 2.9453732684e-06, 3.2884665245e-06, 3.6383895800e-06, 3.9878224217e-06, 4.3298504706e-06, 4.6580313120e-06, 4.9664517572e-06, 5.2497750941e-06, 5.5032785074e-06, 5.7228807660e-06, 5.9051603899e-06, 6.0473646055e-06, 6.1474094983e-06, 6.2038718500e-06, 6.2159732223e-06, 6.1835569145e-06, 6.1070584697e-06, 5.9874704478e-06, 5.8263022146e-06, 5.6255355116e-06, 5.3875765849e-06, 5.1152056481e-06, 4.8115244440e-06, 4.4799026514e-06, 4.1239238569e-06, 3.7473317769e-06, 3.3539773725e-06, 2.9477674568e-06, 2.5326153400e-06, 2.1123940033e-06, 1.6908922361e-06, 1.2717741070e-06, 8.5854208223e-07, 4.5450403794e-07, 6.2744355816e-08, -3.1390077269e-07, -6.7286376522e-07, -1.0118617792e-06, -1.3289085964e-06, -1.6223223537e-06, -1.8907292580e-06, -2.1330634646e-06, -2.3485633372e-06, -2.5367643381e-06, -2.6974888247e-06, -2.8308330538e-06, -2.9371517077e-06, -3.0170402731e-06, -3.0713156082e-06, -3.1009950394e-06, -3.1072743236e-06, -3.0915048107e-06, -3.0551701281e-06, -2.9998626976e-06, -2.9272603793e-06, -2.8391035153e-06, -2.7371726299e-06, -2.6232670130e-06, -2.4991843954e-06, -2.3667018929e-06, -2.2275583733e-06, -2.0834383713e-06, -1.9359576509e-06, -1.7866504848e-06, -1.6369586998e-06, -1.4882225061e-06, -1.3416731099e-06, -1.1984270824e-06, -1.0594824405e-06, -9.2571637381e-07, -7.9788453816e-07, -6.7662181787e-07, -5.6244445003e-07, -4.5575339146e-07, -3.5683880180e-07, -2.6588551026e-07, -1.8297932947e-07, -1.0811407849e-07, -4.1199176753e-08, 1.7932326771e-08, 6.9515421839e-08, 1.1384462961e-07, 1.5126544051e-07, 1.8216581031e-07, 2.0696781862e-07, 2.2611958469e-07, 2.4008752517e-07, 2.4934902788e-07, 2.5438560470e-07, 2.5567657596e-07, 2.5369332733e-07, 2.4889416998e-07, 2.4171982374e-07, 2.3258953374e-07, 2.2189782077e-07, 2.1001185770e-07, 1.9726945559e-07, 1.8397763614e-07, 1.7041176103e-07, 1.5681518263e-07, 1.4339937649e-07, 1.3034451197e-07, 1.1780041475e-07, 1.0588787301e-07, 9.4700237761e-08, 8.4305267918e-08, 7.4747170707e-08, 6.6048789471e-08, 5.8213892520e-08, 5.1229519040e-08, 4.5068340863e-08, 3.9691002072e-08, 3.5048401979e-08, 3.1083890736e-08, 2.7735350818e-08, 2.4937141679e-08, 2.2621888930e-08, 2.0722103492e-08, 1.9171620108e-08, 1.7906848440e-08, 1.6867833605e-08, 1.5999126380e-08, 1.5250466447e-08, 1.4577284871e-08, 1.3941034466e-08, 1.3309358908e-08, 1.2656113242e-08, 1.1961249863e-08}
  COEFFICIENT_WIDTH 24
  QUANTIZATION Quantize_Only
  BESTPRECISION true
  FILTER_TYPE Decimation
  RATE_CHANGE_TYPE Fixed_Fractional
  INTERPOLATION_RATE 24
  DECIMATION_RATE 25
  NUMBER_CHANNELS 8
  NUMBER_PATHS 1
  SAMPLE_FREQUENCY 1.0
  CLOCK_FREQUENCY 125
  OUTPUT_ROUNDING_MODE Convergent_Rounding_to_Even
  OUTPUT_WIDTH 25
  M_DATA_HAS_TREADY true
  HAS_ARESETN true
} {
  S_AXIS_DATA conv_0/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create axis_subset_converter
cell xilinx.com:ip:axis_subset_converter:1.1 subset_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 3
  TDATA_REMAP {tdata[23:0]}
} {
  S_AXIS fir_0/M_AXIS_DATA
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create fir_compiler
cell xilinx.com:ip:fir_compiler:7.2 fir_1 {
  DATA_WIDTH.VALUE_SRC USER
  DATA_WIDTH 24
  COEFFICIENTVECTOR {-1.5065452508e-08, 4.0943712927e-09, 9.7221775254e-09, -3.2389049538e-08, -1.4704201468e-07, -3.2339720796e-07, -4.9277010446e-07, -5.2462292156e-07, -2.5263370210e-07, 4.6611131186e-07, 1.6696416141e-06, 3.2128515930e-06, 4.7273691880e-06, 5.6526716870e-06, 5.3555060700e-06, 3.3259997949e-06, -5.9508806310e-07, -6.0310195579e-06, -1.2007017183e-05, -1.7073026900e-05, -1.9624010651e-05, -1.8362668682e-05, -1.2782673268e-05, -3.5097054698e-06, 7.6550887339e-06, 1.8079018284e-05, 2.5003685516e-05, 2.6451313561e-05, 2.2057276775e-05, 1.3511344257e-05, 4.3497361897e-06, -9.9289108762e-07, 1.2796430718e-06, 1.2600729666e-05, 3.0703483614e-05, 4.9260040131e-05, 5.8902321968e-05, 4.9657429565e-05, 1.4354718619e-05, -4.7883016959e-05, -1.2920859754e-04, -2.1276396493e-04, -2.7519265185e-04, -2.9186366860e-04, -2.4383640549e-04, -1.2482607520e-04, 5.3957862210e-05, 2.6302881727e-04, 4.5898151641e-04, 5.9372595128e-04, 6.2679234899e-04, 5.3762000468e-04, 3.3416419512e-04, 5.4594798252e-05, -2.3962504211e-04, -4.7866625752e-04, -6.0408011110e-04, -5.8809931473e-04, -4.4637871802e-04, -2.3892610212e-04, -5.6618759645e-05, 5.3356125243e-06, -1.1870491068e-04, -4.3275409329e-04, -8.5960432003e-04, -1.2429135106e-03, -1.3757484718e-03, -1.0536097910e-03, -1.4236712574e-04, 1.3549423058e-03, 3.2518600636e-03, 5.1709668726e-03, 6.5868929395e-03, 6.9210602032e-03, 5.6763861109e-03, 2.5878451278e-03, -2.2437472318e-03, -8.2694190410e-03, -1.4490037227e-02, -1.9550015939e-02, -2.1923287318e-02, -2.0167522815e-02, -1.3204820006e-02, -5.7637552546e-04, 1.7381891866e-02, 3.9485206154e-02, 6.3789379490e-02, 8.7819505263e-02, 1.0890628750e-01, 1.2457595363e-01, 1.3292699360e-01, 1.3292699360e-01, 1.2457595363e-01, 1.0890628750e-01, 8.7819505263e-02, 6.3789379490e-02, 3.9485206154e-02, 1.7381891866e-02, -5.7637552546e-04, -1.3204820006e-02, -2.0167522815e-02, -2.1923287318e-02, -1.9550015939e-02, -1.4490037227e-02, -8.2694190410e-03, -2.2437472318e-03, 2.5878451278e-03, 5.6763861109e-03, 6.9210602032e-03, 6.5868929395e-03, 5.1709668726e-03, 3.2518600636e-03, 1.3549423058e-03, -1.4236712574e-04, -1.0536097910e-03, -1.3757484718e-03, -1.2429135106e-03, -8.5960432003e-04, -4.3275409329e-04, -1.1870491068e-04, 5.3356125243e-06, -5.6618759645e-05, -2.3892610212e-04, -4.4637871802e-04, -5.8809931473e-04, -6.0408011110e-04, -4.7866625752e-04, -2.3962504211e-04, 5.4594798252e-05, 3.3416419512e-04, 5.3762000468e-04, 6.2679234899e-04, 5.9372595128e-04, 4.5898151641e-04, 2.6302881727e-04, 5.3957862210e-05, -1.2482607520e-04, -2.4383640549e-04, -2.9186366860e-04, -2.7519265185e-04, -2.1276396493e-04, -1.2920859754e-04, -4.7883016959e-05, 1.4354718619e-05, 4.9657429565e-05, 5.8902321968e-05, 4.9260040131e-05, 3.0703483614e-05, 1.2600729666e-05, 1.2796430718e-06, -9.9289108762e-07, 4.3497361897e-06, 1.3511344257e-05, 2.2057276775e-05, 2.6451313561e-05, 2.5003685516e-05, 1.8079018284e-05, 7.6550887339e-06, -3.5097054698e-06, -1.2782673268e-05, -1.8362668682e-05, -1.9624010651e-05, -1.7073026900e-05, -1.2007017183e-05, -6.0310195579e-06, -5.9508806310e-07, 3.3259997949e-06, 5.3555060700e-06, 5.6526716870e-06, 4.7273691880e-06, 3.2128515930e-06, 1.6696416141e-06, 4.6611131186e-07, -2.5263370210e-07, -5.2462292156e-07, -4.9277010446e-07, -3.2339720796e-07, -1.4704201468e-07, -3.2389049538e-08, 9.7221775254e-09, 4.0943712927e-09, -1.5065452508e-08}
  COEFFICIENT_WIDTH 24
  QUANTIZATION Quantize_Only
  BESTPRECISION true
  FILTER_TYPE Decimation
  RATE_CHANGE_TYPE Fixed_Fractional
  INTERPOLATION_RATE 4
  DECIMATION_RATE 5
  NUMBER_CHANNELS 8
  NUMBER_PATHS 1
  SAMPLE_FREQUENCY 0.96
  CLOCK_FREQUENCY 125
  OUTPUT_ROUNDING_MODE Convergent_Rounding_to_Even
  OUTPUT_WIDTH 25
  M_DATA_HAS_TREADY true
  HAS_ARESETN true
} {
  S_AXIS_DATA subset_0/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create axis_subset_converter
cell xilinx.com:ip:axis_subset_converter:1.1 subset_1 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 3
  TDATA_REMAP {tdata[23:0]}
} {
  S_AXIS fir_1/M_AXIS_DATA
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create fir_compiler
cell xilinx.com:ip:fir_compiler:7.2 fir_2 {
  DATA_WIDTH.VALUE_SRC USER
  DATA_WIDTH 24
  COEFFICIENTVECTOR {-1.5350198227e-08, -3.6841832086e-08, 3.5273638969e-09, 2.4226410807e-08, 8.1563976510e-09, 2.5160464482e-08, 4.5870145728e-09, -1.1781699625e-07, -7.8740696123e-08, 2.4307695615e-07, 2.5862262796e-07, -3.6478129738e-07, -5.8516127528e-07, 4.1635159005e-07, 1.0802159102e-06, -3.0273947829e-07, -1.7288236513e-06, -8.8894827979e-08, 2.4628172842e-06, 8.6848941247e-07, -3.1511455291e-06, -2.1139673635e-06, 3.6019983690e-06, 3.8377946934e-06, -3.5808524858e-06, -5.9560200896e-06, 2.8458981763e-06, 8.2683044462e-06, -1.1986046590e-06, -1.0457794928e-05, -1.4573802351e-06, 1.2117808161e-05, 5.0599816315e-06, -1.2808369161e-05, -9.3493508942e-06, 1.2139030841e-05, 1.3858873982e-05, -9.8703715478e-06, -1.7953203270e-05, 6.0106219578e-06, 2.0911868740e-05, -8.9296707753e-07, -2.2062903154e-05, -4.7968980428e-06, 2.0947867158e-05, 1.0061789746e-05, -1.7493696325e-05, -1.3716085198e-05, 1.2155922807e-05, 1.4589593230e-05, -5.9941637142e-06, -1.1794233097e-05, 6.4301239290e-07, 5.0166706225e-06, 1.8469241372e-06, 5.2152090781e-06, 6.9570233860e-07, -1.7354101915e-05, -1.0151939908e-05, 2.8801384630e-05, 2.7625902108e-05, -3.6085903128e-05, -5.2984275240e-05, 3.5237211325e-05, 8.4467622804e-05, -2.2389599362e-05, -1.1851855510e-04, -5.4780228872e-06, 1.4988622349e-04, 4.9750479354e-05, -1.7206898151e-04, -1.0946992223e-04, 1.7809843499e-04, 1.8086454932e-04, -1.6160848961e-04, -2.5725737490e-04, 1.1806555666e-04, 3.2946381129e-04, -4.5979015997e-05, -3.8672594592e-04, -5.2129612244e-05, 4.1814464110e-04, 1.6922446738e-04, -4.1448749704e-04, -2.9395420580e-04, 3.7007094661e-04, 4.1155903181e-04, -2.8458254057e-04, -5.0571576404e-04, 1.6427233919e-04, 5.6099406062e-04, -2.2347777602e-05, -5.6577972738e-04, -1.2176376760e-04, 5.1523779960e-04, 2.4441090045e-04, -4.1383190794e-04, -3.2093836209e-04, 2.7687559169e-04, 3.2988848927e-04, -1.3063566288e-04, -2.5773680647e-04, 1.0628660925e-05, 1.0353335156e-04, 4.2043582301e-05, 1.1729201021e-04, 1.3776554773e-05, -3.7078213369e-04, -2.1245089681e-04, 6.0436113882e-04, 5.7356828982e-04, -7.4999883223e-04, -1.0946323327e-03, 7.2990740453e-04, 1.7446196716e-03, -4.6530371094e-04, -2.4599797408e-03, -1.1260827101e-04, 3.1438968072e-03, 1.0503167879e-03, -3.6695110890e-03, -2.3595702792e-03, 3.8873800586e-03, 4.0062124180e-03, -3.6369774447e-03, -5.9016442599e-03, 2.7615031607e-03, 7.8980337921e-03, -1.1247951126e-03, -9.7879276305e-03, -1.3712929641e-03, 1.1307933782e-02, 4.7700352473e-03, -1.2147072252e-02, -9.0479737853e-03, 1.1953449530e-02, 1.4104524735e-02, -1.0340022282e-02, -1.9758443589e-02, 6.8773992274e-03, 2.5747338920e-02, -1.0593999427e-03, -3.1726476342e-02, -7.7942840851e-03, 3.7252977705e-02, 2.0790404268e-02, -4.1709616976e-02, -4.0156669495e-02, 4.3979453722e-02, 7.1505363135e-02, -4.0782256769e-02, -1.3385354210e-01, 1.2641978772e-02, 3.3825481085e-01, 5.1190054421e-01, 3.3825481085e-01, 1.2641978772e-02, -1.3385354210e-01, -4.0782256769e-02, 7.1505363135e-02, 4.3979453722e-02, -4.0156669495e-02, -4.1709616976e-02, 2.0790404268e-02, 3.7252977705e-02, -7.7942840851e-03, -3.1726476342e-02, -1.0593999427e-03, 2.5747338920e-02, 6.8773992274e-03, -1.9758443589e-02, -1.0340022282e-02, 1.4104524735e-02, 1.1953449530e-02, -9.0479737853e-03, -1.2147072252e-02, 4.7700352473e-03, 1.1307933782e-02, -1.3712929641e-03, -9.7879276305e-03, -1.1247951126e-03, 7.8980337921e-03, 2.7615031607e-03, -5.9016442599e-03, -3.6369774447e-03, 4.0062124180e-03, 3.8873800586e-03, -2.3595702792e-03, -3.6695110890e-03, 1.0503167879e-03, 3.1438968072e-03, -1.1260827101e-04, -2.4599797408e-03, -4.6530371094e-04, 1.7446196716e-03, 7.2990740453e-04, -1.0946323327e-03, -7.4999883223e-04, 5.7356828982e-04, 6.0436113882e-04, -2.1245089681e-04, -3.7078213369e-04, 1.3776554773e-05, 1.1729201021e-04, 4.2043582301e-05, 1.0353335156e-04, 1.0628660925e-05, -2.5773680647e-04, -1.3063566288e-04, 3.2988848927e-04, 2.7687559169e-04, -3.2093836209e-04, -4.1383190794e-04, 2.4441090045e-04, 5.1523779960e-04, -1.2176376760e-04, -5.6577972738e-04, -2.2347777602e-05, 5.6099406062e-04, 1.6427233919e-04, -5.0571576404e-04, -2.8458254057e-04, 4.1155903181e-04, 3.7007094661e-04, -2.9395420580e-04, -4.1448749704e-04, 1.6922446738e-04, 4.1814464110e-04, -5.2129612244e-05, -3.8672594592e-04, -4.5979015997e-05, 3.2946381129e-04, 1.1806555666e-04, -2.5725737490e-04, -1.6160848961e-04, 1.8086454932e-04, 1.7809843499e-04, -1.0946992223e-04, -1.7206898151e-04, 4.9750479354e-05, 1.4988622349e-04, -5.4780228872e-06, -1.1851855510e-04, -2.2389599362e-05, 8.4467622804e-05, 3.5237211325e-05, -5.2984275240e-05, -3.6085903128e-05, 2.7625902108e-05, 2.8801384630e-05, -1.0151939908e-05, -1.7354101915e-05, 6.9570233860e-07, 5.2152090781e-06, 1.8469241372e-06, 5.0166706225e-06, 6.4301239290e-07, -1.1794233097e-05, -5.9941637142e-06, 1.4589593230e-05, 1.2155922807e-05, -1.3716085198e-05, -1.7493696325e-05, 1.0061789746e-05, 2.0947867158e-05, -4.7968980428e-06, -2.2062903154e-05, -8.9296707753e-07, 2.0911868740e-05, 6.0106219578e-06, -1.7953203270e-05, -9.8703715478e-06, 1.3858873982e-05, 1.2139030841e-05, -9.3493508942e-06, -1.2808369161e-05, 5.0599816315e-06, 1.2117808161e-05, -1.4573802351e-06, -1.0457794928e-05, -1.1986046590e-06, 8.2683044462e-06, 2.8458981763e-06, -5.9560200896e-06, -3.5808524858e-06, 3.8377946934e-06, 3.6019983690e-06, -2.1139673635e-06, -3.1511455291e-06, 8.6848941247e-07, 2.4628172842e-06, -8.8894827979e-08, -1.7288236513e-06, -3.0273947829e-07, 1.0802159102e-06, 4.1635159005e-07, -5.8516127528e-07, -3.6478129738e-07, 2.5862262796e-07, 2.4307695615e-07, -7.8740696123e-08, -1.1781699625e-07, 4.5870145728e-09, 2.5160464482e-08, 8.1563976510e-09, 2.4226410807e-08, 3.5273638969e-09, -3.6841832086e-08, -1.5350198227e-08}
  COEFFICIENT_WIDTH 24
  QUANTIZATION Quantize_Only
  BESTPRECISION true
  FILTER_TYPE Decimation
  DECIMATION_RATE 2
  NUMBER_CHANNELS 8
  NUMBER_PATHS 1
  SAMPLE_FREQUENCY 0.768
  CLOCK_FREQUENCY 125
  OUTPUT_ROUNDING_MODE Convergent_Rounding_to_Even
  OUTPUT_WIDTH 26
  M_DATA_HAS_TREADY true
  HAS_ARESETN true
} {
  S_AXIS_DATA subset_1/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter:1.1 conv_1 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 32
} {
  S_AXIS fir_2/M_AXIS_DATA
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create axis_subset_converter
cell xilinx.com:ip:axis_subset_converter:1.1 subset_2 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 32
  M_TDATA_NUM_BYTES 32
  TDATA_REMAP {tdata[23:16],tdata[39:32],tdata[47:40],tdata[55:48],16'b0000000000000000,tdata[7:0],tdata[15:8],tdata[87:80],tdata[103:96],tdata[111:104],tdata[119:112],16'b0000000000000000,tdata[71:64],tdata[79:72],tdata[151:144],tdata[167:160],tdata[175:168],tdata[183:176],16'b0000000000000000,tdata[135:128],tdata[143:136],tdata[215:208],tdata[231:224],tdata[239:232],tdata[247:240],16'b0000000000000000,tdata[199:192],tdata[207:200]}
} {
  S_AXIS conv_1/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create fifo_generator
cell xilinx.com:ip:fifo_generator:13.1 fifo_generator_0 {
  PERFORMANCE_OPTIONS First_Word_Fall_Through
  INPUT_DATA_WIDTH 256
  INPUT_DEPTH 1024
  OUTPUT_DATA_WIDTH 32
  OUTPUT_DEPTH 8192
  READ_DATA_COUNT true
  READ_DATA_COUNT_WIDTH 14
} {
  clk /ps_0/FCLK_CLK0
  srst slice_0/Dout
}

# Create axis_fifo
cell pavel-demin:user:axis_fifo:1.0 fifo_1 {
  S_AXIS_TDATA_WIDTH 256
  M_AXIS_TDATA_WIDTH 32
} {
  S_AXIS subset_2/M_AXIS
  FIFO_READ fifo_generator_0/FIFO_READ
  FIFO_WRITE fifo_generator_0/FIFO_WRITE
  aclk /ps_0/FCLK_CLK0
}

# Create axi_axis_reader
cell pavel-demin:user:axi_axis_reader:1.0 reader_0 {
  AXI_DATA_WIDTH 32
} {
  S_AXIS fifo_1/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}
