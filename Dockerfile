FROM ubuntu:20.04

USER root

ARG DEBIAN_FRONTEND=noninteractive

# Add dependencies
RUN apt-get update && apt-get install -y libxml2 libxml2-dev 
RUN apt-get update && apt-get install -y libcurl4-gnutls-dev libssl-dev curl
RUN apt-get update && apt-get install -y git curl
RUN apt-get update && apt-get install -y r-cran-rgl

RUN mkdir /tmp/downloads

RUN curl -sSL -o tmp.tar.gz --retry 10 https://github.com/samtools/htslib/archive/1.7.tar.gz && \
    mkdir /tmp/downloads/htslib && \
    tar -C /tmp/downloads/htslib --strip-components 1 -zxf tmp.tar.gz && \
    make -C /tmp/downloads/htslib && \
    rm -f /tmp/downloads/tmp.tar.gz

ENV HTSLIB /tmp/downloads/htslib

RUN curl -sSL -o tmp.tar.gz --retry 10 https://github.com/cancerit/alleleCount/archive/v4.0.0.tar.gz && \
    mkdir /tmp/downloads/alleleCount && \
    tar -C /tmp/downloads/alleleCount --strip-components 1 -zxf tmp.tar.gz && \
    cd /tmp/downloads/alleleCount/c && \
    mkdir bin && \
    make && \
    cp /tmp/downloads/alleleCount/c/bin/alleleCounter /usr/local/bin/. && \
    cd /tmp/downloads && \
    rm -rf /tmp/downloads/alleleCount /tmp/downloads/tmp.tar.gz

RUN curl -sSL -o tmp.tar.gz --retry 10 https://mathgen.stats.ox.ac.uk/impute/impute_v2.3.2_x86_64_static.tgz && \
    mkdir /tmp/downloads/impute2 && \
    tar -C /tmp/downloads/impute2 --strip-components 1 -zxf tmp.tar.gz && \
    cp /tmp/downloads/impute2/impute2 /usr/local/bin && \
    rm -rf /tmp/downloads/impute2 /tmp/downloads/tmp.tar.gz

RUN R -e 'install.packages("BiocManager"); library("BiocManager")'
RUN R -e 'BiocManager::install("remotes"); library("remotes")'
RUN R -e 'BiocManager::install("gtools"); library("gtools")'
RUN R -e 'BiocManager::install("optparse"); library("optparse")'
RUN R -e 'BiocManager::install("devtools"); library("devtools")'
RUN R -e 'BiocManager::install("RColorBrewer"); library("RColorBrewer")'
RUN R -e 'BiocManager::install("ggplot2"); library("ggplot2")'
RUN R -e 'BiocManager::install("gridExtra"); library("gridExtra")'
RUN R -e 'BiocManager::install("readr"); library("readr")'
RUN R -e 'BiocManager::install("doParallel"); library("doParallel")'
RUN R -e 'BiocManager::install("foreach"); library("foreach")'
RUN R -e 'BiocManager::install("splines"); library("splines")'
RUN R -e 'BiocManager::install("Crick-CancerGenomics/ascat/ASCAT"); library("ASCAT")'

RUN mkdir -p /opt/battenberg
COPY . /opt/battenberg/
RUN R -q -e 'install.packages("/opt/battenberg", repos=NULL, type="source")'

# modify paths to reference files
RUN cat /opt/battenberg/inst/example/battenberg_wgs.R | \
    sed 's|IMPUTEINFOFILE = \".*|IMPUTEINFOFILE = \"/opt/battenberg_reference/1000genomes_2012_v3_impute/impute_info.txt\"|' | \
    sed 's|G1000PREFIX = \".*|G1000PREFIX = \"/opt/battenberg_reference/1000genomes_2012_v3_loci/1000genomesAlleles2012_chr\"|' | \
    sed 's|G1000PREFIX_AC = \".*|G1000PREFIX_AC = \"/opt/battenberg_reference/1000genomes_2012_v3_loci/1000genomesloci2012_chr\"|' | \
    sed 's|GCCORRECTPREFIX = \".*|GCCORRECTPREFIX = \"/opt/battenberg_reference/1000genomes_2012_v3_gcContent/1000_genomes_GC_corr_chr_\"|' | \
    sed 's|PROBLEMLOCI = \".*|PROBLEMLOCI = \"/opt/battenberg_reference/battenberg_problem_loci/probloci_270415.txt.gz\"|' | \
    sed 's|REPLICCORRECTPREFIX = \".*|REPLICCORRECTPREFIX = \"/opt/battenberg_reference/battenberg_wgs_replic_correction_1000g_v3/1000_genomes_replication_timing_chr_\"|' > /usr/local/bin/battenberg_wgs.R

RUN cp /opt/battenberg/inst/example/filter_sv_brass.R /usr/local/bin/filter_sv_brass.R
RUN cp /opt/battenberg/inst/example/battenberg_cleanup.sh /usr/local/bin/battenberg_cleanup.sh

#RUN cat /opt/battenberg/inst/example/battenberg_snp6.R | \
#    sed 's|IMPUTEINFOFILE = \".*|IMPUTEINFOFILE = \"/opt/battenberg_reference/1000genomes_2012_v3_impute/impute_info.txt\"|' | \
#    sed 's|G1000PREFIX = \".*|G1000PREFIX = \"/opt/battenberg_reference/1000genomes_2012_v3_loci/1000genomesAlleles2012_chr\"|' | \
#    sed 's|SNP6_REF_INFO_FILE = \".*|SNP6_REF_INFO_FILE = \"/opt/battenberg_reference/battenberg_snp6/snp6_ref_info_file.txt\"|' > /usr/local/bin/battenberg_snp6.R

## USER CONFIGURATION
RUN adduser --disabled-password --gecos '' ubuntu && chsh -s /bin/bash && mkdir -p /home/ubuntu

USER    ubuntu
WORKDIR /home/ubuntu

CMD ["/bin/bash"]
