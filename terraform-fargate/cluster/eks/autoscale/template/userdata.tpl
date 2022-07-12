MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==TEMPBOUNDARY=="

--==TEMPBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -ex
/etc/eks/bootstrap.sh ${CLUSTER_NAME} --b64-cluster-ca ${B64_CLUSTER_CA} --apiserver-endpoint ${API_SERVER_URL}

--==TEMPBOUNDARY==--\