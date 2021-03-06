FROM atlas/analysisbase:21.2.102

# We need a messy bunch of stuff to make sure we can properly access GRID resources using
# x509 certs.
# WARNING: THis is for CentOS (modern versions of analysisbase)
# TODO: Ask about a better way to deal with this.
#
# "sudo yum -y update" breaks the container due to a bad path in some of the ATLAS RPM's.
# So it must be disabled until it is fixed on the ATLAS end:
#   https://sft.its.cern.ch/jira/browse/SPI-1654
# Unfortunately, the lack of this means the rucioN2N won't work either due to a library
# conflict. Once that jira is resolved:
#   1. Remove the comment below
#   1. Turn back on the rucioN2N installation below
#   1. Test (access a xroot file, compile C++ code)
#   1. Delete this comment. :-)
RUN sudo yum -y update

RUN sudo yum install -y https://repo.opensciencegrid.org/osg/3.5/osg-3.5-el7-release-latest.rpm
# RUN sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN sudo curl -s -o /etc/pki/rpm-gpg/RPM-GPG-KEY-wlcg http://linuxsoft.cern.ch/wlcg/RPM-GPG-KEY-wlcg
RUN sudo curl -s -o /etc/yum.repos.d/wlcg-centos7.repo http://linuxsoft.cern.ch/wlcg/wlcg-centos7.repo;
RUN sudo yum install -y xrootd-server xrootd-client xrootd \
    xrootd-voms voms-clients wlcg-voms-atlas fetch-crl osg-ca-certs
#    xrootd-rucioN2N-for-Xcache

# Install everything needed to host/run the analysis jobs
RUN sudo mkdir -p /etc/grid-security/certificates /etc/grid-security/vomsdir
WORKDIR /servicex
COPY bashrc /servicex/.bashrc
COPY bashrc /servicex/.bash_profile
COPY requirements.txt .
RUN source /home/atlas/release_setup.sh; \
    python2 -m pip install --user safety==1.8.7
RUN source /home/atlas/release_setup.sh; \
    safety check -r requirements.txt; \
    python2 -m pip install --user -r requirements.txt

# Turn this on so that stdout isn't buffered - otherwise logs in kubectl don't
# show up until much later!
ENV PYTHONUNBUFFERED=1
ENV X509_USER_PROXY=/etc/grid-security/x509up

# Copy over the source
COPY proxy-exporter.sh .
COPY validate_requests.py .

COPY transformer.py .
WORKDIR /home/atlas
